# Security Domain Invariants

Extends: [[system-invariants]]
Domain: API security, authentication, authorization, data protection, web security

<!-- Invariant Range: 66-75 (Security reserved range)
     Numbering scheme: Core 1-11, Consumer 12-15, Integration 16-19, Data 20-24, Healthcare 25-31, HLS-SA 32-39, Construction 40-47, Remote 48-55, SkillGap 56-65, Security 66-75
     Reserved ranges allow domains to evolve independently -->

---

## When to Use

Load this domain for:
- API route development (REST, GraphQL)
- Authentication/authorization implementations
- User data handling
- File upload features
- Redirect handling
- Database operations with user input
- Any feature handling sensitive data

---

## Domain Invariants (66-75)

### 66. Every API Route Must Have Authentication

**Principle**: API routes that read or write data must verify the user is authenticated

**Violation**: Unauthenticated endpoints, missing auth checks, auth bypass

**Examples**:
- ❌ "Create API endpoint for order scan"
- ❌ "Add POST handler for data extraction"
- ❌ "Build endpoint to check duplicates"
- ✅ "POST /api/orders/scan: getUser() + 401_if_no_user + proceed_with_user_context"
- ✅ "POST /api/extract: auth_check(first_line) + early_return_401 + audit_log(user_id)"
- ✅ "GET /api/seasons: createClient() + getUser() + reject_anonymous"

**Enforcement**: Every API route must have auth check as first operation → Otherwise REJECT

**Pattern**:
```typescript
const supabase = await createClient();
const { data: { user }, error: authError } = await supabase.auth.getUser();
if (authError || !user) {
  return NextResponse.json({ error: 'Authentication required' }, { status: 401 });
}
```

---

### 67. Admin Operations Must Check Role

**Principle**: Operations that create, update, or delete master data must verify admin role

**Violation**: Role checks only in middleware, missing API-level role verification

**Examples**:
- ❌ "Create season (admin page so safe)"
- ❌ "Delete fabric (middleware checks role)"
- ❌ "Update buyer information"
- ✅ "Create season: auth_check + role_check(admin) + 403_if_not_admin"
- ✅ "Delete fabric: getUser() + fetch_profile_role + explicit_admin_verify"
- ✅ "Update buyer: auth + role_from_profiles_table + reject_non_admin"

**Enforcement**: Master data mutations must include: auth_check + role_fetch + admin_verify → Otherwise REJECT

**Why**: Middleware role checks protect UI routes, not API endpoints. Direct API calls bypass middleware.

**Pattern**:
```typescript
const { data: profile } = await supabase
  .from('profiles')
  .select('role')
  .eq('id', user.id)
  .single();

if (!profile || profile.role !== 'admin') {
  return NextResponse.json({ error: 'Admin access required' }, { status: 403 });
}
```

---

### 68. URL Parameters Must Be Encoded

**Principle**: User-supplied values in URLs must be encoded with encodeURIComponent()

**Violation**: Raw user input in URLs, unencoded query parameters

**Examples**:
- ❌ "`fetch(\`/api/orders?id=eq.${id}\`)`"
- ❌ "Build URL with user-supplied season code"
- ❌ "Construct Supabase REST URL from params"
- ✅ "`fetch(\`/api/orders?id=eq.${encodeURIComponent(id)}\`)`"
- ✅ "URL construction: encode_all_params + validate_format + safe_interpolation"
- ✅ "REST query: encodeURIComponent(value) + parameterized_queries"

**Enforcement**: User values in URLs must use encodeURIComponent() → Otherwise REJECT

**Why**: Unencoded parameters allow SQL injection via REST API query syntax (e.g., `id=eq.1;DELETE FROM orders--`)

---

### 69. Mutation Fields Must Be Whitelisted

**Principle**: When accepting data for updates, explicitly whitelist allowed fields

**Violation**: Passing client data directly to database, spreading request body into updates

**Examples**:
- ❌ "`await supabase.update(req.body)`"
- ❌ "`const updates = { ...clientData }`"
- ❌ "Update order with all provided fields"
- ✅ "Order update: allowedFields=['status','notes','buyer_id'] + filter_keys + sanitize"
- ✅ "Profile edit: whitelist_check + reject_protected_fields(role,created_at)"
- ✅ "Batch update: per_field_validation + explicit_allowed_list + audit_log"

**Enforcement**: Update operations must define allowed_fields whitelist → Otherwise REJECT

**Pattern**:
```typescript
const allowedFields = ['status', 'notes', 'buyer_id'];
const sanitizedUpdate = Object.keys(clientData)
  .filter(key => allowedFields.includes(key))
  .reduce((obj, key) => ({ ...obj, [key]: clientData[key] }), {});
```

---

### 70. File Names Must Be Sanitized

**Principle**: User-supplied file names must be sanitized before use in paths

**Violation**: Using raw filename from upload, path traversal possible

**Examples**:
- ❌ "`const path = \`uploads/${file.name}\``"
- ❌ "Save file with original filename"
- ❌ "Use client-provided filename for storage"
- ✅ "Upload: sanitize_name(remove_special_chars) + limit_length(50) + prepend_timestamp"
- ✅ "File save: regex_whitelist([a-zA-Z0-9._-]) + fallback_name('file') + unique_prefix"
- ✅ "Storage path: sanitized_name + uuid_prefix + no_path_separators_allowed"

**Enforcement**: File operations must sanitize filename → Otherwise REJECT

**Pattern**:
```typescript
const sanitizedName = file.name
  .replace(/[^a-zA-Z0-9._-]/g, '')  // Remove special chars
  .slice(0, 50);  // Limit length
const fileName = `uploads/${Date.now()}-${sanitizedName || 'file'}`;
```

---

### 71. Redirect URLs Must Be Validated

**Principle**: Redirect destinations from user input must be validated as relative URLs

**Violation**: Open redirects, protocol-relative URLs, external domain redirects

**Examples**:
- ❌ "`redirect(req.query.next)`"
- ❌ "Return to URL from query parameter"
- ❌ "Post-login redirect to ?redirect param"
- ✅ "Redirect: validate_starts_with_slash + reject_double_slash + same_origin_only"
- ✅ "Post-login: whitelist_paths(['/','/dashboard']) + fallback_to_home"
- ✅ "Return URL: isValidRedirectUrl() + reject_external + default_safe_path"

**Enforcement**: Redirect URLs must validate: starts_with_slash + not_protocol_relative → Otherwise REJECT

**Pattern**:
```typescript
function isValidRedirectUrl(url: string): boolean {
  return url.startsWith('/') && !url.startsWith('//');
}
```

---

### 72. Every Table Must Have RLS Policies

**Principle**: Database tables must have Row Level Security enabled with appropriate policies

**Violation**: Tables without RLS, permissive policies, missing role checks

**Examples**:
- ❌ "Create orders table (will add RLS later)"
- ❌ "New table for user data"
- ❌ "Add colors table to schema"
- ✅ "Orders table: ENABLE RLS + SELECT(authenticated) + INSERT(authenticated) + UPDATE(owner_or_admin) + DELETE(admin_only)"
- ✅ "User data: RLS_enabled + policy_per_operation + role_based_access"
- ✅ "Master data table: RLS + all_read + admin_write + explicit_policies"

**Enforcement**: CREATE TABLE must include: ALTER TABLE ENABLE RLS + policies for all operations → Otherwise REJECT

**Checklist**:
- [ ] `ALTER TABLE tablename ENABLE ROW LEVEL SECURITY;`
- [ ] SELECT policy for authenticated users
- [ ] INSERT/UPDATE/DELETE policies with role checks

---

### 73. Security Headers Must Be Set

**Principle**: All responses must include security headers

**Violation**: Missing security headers, XSS/clickjacking vulnerabilities

**Examples**:
- ❌ "Return JSON response"
- ❌ "Send HTML page"
- ❌ "API response without headers"
- ✅ "Response: X-Content-Type-Options(nosniff) + X-Frame-Options(DENY) + X-XSS-Protection(1;mode=block)"
- ✅ "Middleware: addSecurityHeaders(response) + Referrer-Policy(strict-origin-when-cross-origin)"
- ✅ "All routes: security_headers_middleware + CSP_policy"

**Enforcement**: Response handling must set security headers → Otherwise REJECT

**Required Headers**:
```typescript
response.headers.set('X-Content-Type-Options', 'nosniff');
response.headers.set('X-Frame-Options', 'DENY');
response.headers.set('X-XSS-Protection', '1; mode=block');
response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
```

---

### 74. Secrets Must Not Be In Code

**Principle**: API keys, tokens, and credentials must be in environment variables

**Violation**: Hardcoded secrets, committed credentials, exposed keys

**Examples**:
- ❌ "`const API_KEY = 'sk-abc123...'`"
- ❌ "Add Stripe key to config file"
- ❌ "Include test credentials in code"
- ✅ "API key: process.env.API_KEY + env_validation_on_startup + error_if_missing"
- ✅ "Stripe: STRIPE_SECRET_KEY from env + .env in .gitignore + Vercel env vars for prod"
- ✅ "Credentials: env_only + rotation_capable + no_logging"

**Enforcement**: No literal API keys/tokens in source → Otherwise REJECT

**Checklist**:
- [ ] `.env` and `.env.local` in `.gitignore`
- [ ] No hardcoded API keys in source
- [ ] Secrets rotated if ever exposed
- [ ] Use Vercel/hosting environment variables for production

---

### 75. Error Messages Must Be Generic

**Principle**: Error responses to clients must not include internal details

**Violation**: Exposing stack traces, database errors, internal paths

**Examples**:
- ❌ "`return { error: error.message }`"
- ❌ "Return database error to client"
- ❌ "Include stack trace in response"
- ✅ "Error handling: console.error(internal_details) + return_generic_message + log_correlation_id"
- ✅ "DB error: log_full_error_server_side + respond('Operation failed',500) + no_table_names"
- ✅ "Validation error: user_friendly_message + no_field_internals + actionable_guidance"

**Enforcement**: Error responses must be generic with internal logging → Otherwise REJECT

**Pattern**:
```typescript
// WRONG
return NextResponse.json({ error: error.message }, { status: 500 });

// CORRECT
console.error('Database error:', error);  // Log internally
return NextResponse.json({ error: 'Operation failed' }, { status: 500 });
```

---

## Security-Specific Sub-Invariants

### 75a. Input Validation

- All user input must be validated before use
- Validate type, length, format, and range
- Use allowlists over denylists when possible
- Sanitize for context (HTML, SQL, URLs)

### 75b. Session Management

- Sessions must have expiration
- Session tokens must be cryptographically random
- Logout must invalidate server-side session
- Concurrent session limits where appropriate

### 75c. Audit Logging

- Security-relevant actions must be logged
- Logs must include: user_id, action, timestamp, outcome
- Logs must not contain sensitive data (passwords, tokens)
- Logs must be tamper-resistant

### 75d. Dependency Security

- Dependencies must be regularly updated
- Known vulnerabilities must be addressed promptly
- Lockfiles must be committed
- Supply chain security considered

---

## Security Checklist for New Features

Before merging any PR, verify:

- [ ] All new API routes have authentication
- [ ] Admin operations check role
- [ ] URL parameters are encoded
- [ ] Mutation fields are whitelisted
- [ ] File names are sanitized
- [ ] Redirects are validated
- [ ] New tables have RLS policies
- [ ] No secrets in code
- [ ] Error messages are generic
- [ ] Security headers are set

---

## Quick Reference

| # | Invariant | Key Test |
|---|-----------|----------|
| 66 | Every API Route Must Have Authentication | getUser() check first |
| 67 | Admin Operations Must Check Role | profile.role === 'admin' |
| 68 | URL Parameters Must Be Encoded | encodeURIComponent() used |
| 69 | Mutation Fields Must Be Whitelisted | allowedFields filter |
| 70 | File Names Must Be Sanitized | regex + length limit |
| 71 | Redirect URLs Must Be Validated | starts with / not // |
| 72 | Every Table Must Have RLS | ENABLE ROW LEVEL SECURITY |
| 73 | Security Headers Must Be Set | X-Frame-Options etc. |
| 74 | Secrets Must Not Be In Code | env vars only |
| 75 | Error Messages Must Be Generic | log internal, return generic |

---

*Domain: Security*
*Invariants: 66-75 (plus sub-invariants)*
*Use with: Core invariants 1-11*
*Often combined with: integration.md, data-architecture.md*
*Source: Security audit of Fashion Workflow MVP (2026-02-02)*
