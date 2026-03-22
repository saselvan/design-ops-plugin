# Design-Ops MCP Server

Exposes design-ops validation rules and project patterns via Model Context Protocol.

## What It Does

Allows Claude Code agents to dynamically query validation rules during RALPH pipeline execution:

- **get_invariants**: Get all 43 system invariants
- **get_security_rules**: Get 9 security validation rules
- **get_project_conventions**: Get project-specific CONVENTIONS.md
- **validate_spec_snippet**: Quick validation of spec text

## Installation

### Step 1: Add to Claude Code MCP Configuration

**Location**: `~/.claude/config.json`

Add this to the `mcpServers` section:

```json
{
  "mcpServers": {
    "design-ops": {
      "command": "python3",
      "args": [
        "/Users/YOUR_USERNAME/.claude/design-ops/enforcement/mcp/design-ops-server.py"
      ]
    }
  }
}
```

**IMPORTANT**: Replace `YOUR_USERNAME` with your actual username.

### Step 2: Restart Claude Code

```bash
# If running in terminal mode, just restart
# If running as VS Code extension, reload window
```

### Step 3: Verify It Works

In Claude Code, try:

```
Use the design-ops MCP server to get all invariants
```

You should see the 43 invariants returned.

## Usage Examples

### Get All Invariants

```
Get the design-ops invariants using MCP
```

**Returns**: All 43 system invariants from system-invariants.md

### Get Security Rules

```
Get the security validation rules from design-ops
```

**Returns**: 9 security rules (SEC-001 through SEC-009)

### Validate Spec Snippet

```
Validate this spec text against design-ops rules:
"The system should properly handle user authentication"
```

**Returns**: Issues found (e.g., vague word "properly")

### Get Project Conventions

```
Get project conventions for /path/to/project
```

**Returns**: CONVENTIONS.md content if it exists

## Benefits During RALPH

1. **Dynamic Rule Access**: Agents can query rules without reading full files
2. **Validation on Demand**: Check spec snippets before committing
3. **Context-Aware**: Get project-specific conventions
4. **Faster Feedback**: No need to re-read 43 invariants every time

## Testing the Server

Test manually with this script:

```bash
cd ~/.claude/design-ops/enforcement/mcp

# Test tools/list
echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | python3 design-ops-server.py

# Test get_invariants
echo '{"jsonrpc":"2.0","method":"tools/call","id":2,"params":{"name":"get_invariants","arguments":{}}}' | python3 design-ops-server.py
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│           Claude Code Agent (GATE 1)            │
│                                                 │
│  "I need to check invariants before fixing"    │
└─────────────────┬───────────────────────────────┘
                  │
                  │ MCP Request
                  ▼
┌─────────────────────────────────────────────────┐
│          design-ops-server.py                   │
│                                                 │
│  - get_invariants()                            │
│  - get_security_rules()                        │
│  - validate_spec_snippet()                     │
│  - get_project_conventions()                   │
└─────────────────┬───────────────────────────────┘
                  │
                  │ Reads
                  ▼
┌─────────────────────────────────────────────────┐
│   ~/.claude/design-ops/system-invariants.md    │
│   ~/.claude/design-ops/enforcement/lib/*.sh    │
│   <project>/CONVENTIONS.md                     │
└─────────────────────────────────────────────────┘
```

## Troubleshooting

### Server Not Showing Up

1. Check config.json path is correct
2. Verify python3 is in PATH: `which python3`
3. Check server starts: `python3 design-ops-server.py` (should not error)
4. Check Claude Code logs

### Tools Not Working

1. Test server manually with echo commands above
2. Check system-invariants.md exists
3. Check file permissions

### Performance Issues

- MCP responses are truncated to 5000 chars to avoid timeouts
- If you need full content, use Read tool directly instead
