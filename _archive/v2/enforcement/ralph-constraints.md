# RALPH Gate Constraints - READ THIS FIRST

## 🚨 CRITICAL: You Are Operating in a Stateless Gate

**What "Stateless" Means:**
- You see ONLY the latest committed files
- You see ONLY errors from the last gate run
- You do NOT see the full conversation history
- You do NOT know what happened in previous gates
- Each gate is a fresh start

**Why This Matters:**
- Git commits are how gates communicate
- Without commits, your work disappears
- Next gate won't see your changes unless committed

---

## 🎯 Your ONE Job For This Gate

**DO:**
- ✅ Run the validation command for THIS gate
- ✅ Read the instruction/error file if validation fails
- ✅ Fix ONLY what the instruction says
- ✅ Commit after EVERY fix
- ✅ Re-validate after EVERY commit
- ✅ Loop until PASS

**DO NOT:**
- ❌ Add features not in this gate's scope
- ❌ Refactor code outside this gate
- ❌ Optimize code prematurely
- ❌ Add "nice to have" improvements
- ❌ Fix issues from other gates
- ❌ Skip the commit step
- ❌ Batch multiple fixes before committing

---

## 🔄 The Loop (Follow Exactly)

```
1. ASSESS     → Run validation command
   ↓
2. IF PASS    → Mark task complete, STOP
   ↓
3. IF FAIL:
   3a. READ   → Read instruction/error file
   3b. FIX    → Fix ONLY what instruction says
   3c. COMMIT → git add + git commit (MANDATORY)
   3d. VERIFY → git log (check commit exists)
   3e. VALIDATE → Re-run validation command
   3f. LOOP   → Go back to step 1
```

**Critical Rules:**
- ONE fix per loop iteration
- ONE commit per fix
- NO batching multiple fixes
- NO skipping commit
- NO moving to next step until current step passes

---

## 🚫 Anti-Patterns (What NOT To Do)

### ❌ DON'T: Add Extra Features
```
Instruction: "Add error handling for empty email"
BAD:  Also add password validation, rate limiting, and logging
GOOD: Only add error handling for empty email
```

### ❌ DON'T: Refactor Outside Scope
```
Instruction: "Fix login function to hash passwords"
BAD:  Also refactor entire auth module and update tests
GOOD: Only add password hashing to login function
```

### ❌ DON'T: Batch Fixes Before Committing
```
Instruction: "Fix 3 issues: missing validation, no error handling, unclear variable names"
BAD:  Fix all 3, then commit once
GOOD: Fix issue 1 → commit → Fix issue 2 → commit → Fix issue 3 → commit
```

### ❌ DON'T: Skip Verification
```
BAD:  git commit → immediately re-validate
GOOD: git commit → git log -1 → verify commit exists → then re-validate
```

### ❌ DON'T: Assume You Know Better
```
Instruction: "Use bcrypt for password hashing"
BAD:  I'll use argon2 instead, it's more secure
GOOD: Use bcrypt exactly as instructed
```

---

## 💡 Remember

1. **Your job is NARROW**: Fix what fails, nothing more
2. **Commits are MANDATORY**: Every fix must be committed
3. **Trust the system**: The gates are designed to catch everything
4. **No speculation**: Don't add "what if" features
5. **Stay in your lane**: Other gates handle other concerns

---

## ✅ Success Looks Like This

```
GATE 3: STRESS_TEST
  ↓
Run stress-test → FAIL (missing edge cases section)
  ↓
Read instruction → "Add edge cases section"
  ↓
Edit spec → Add edge cases section
  ↓
git add + git commit -m "ralph: GATE 3 - add edge cases section"
  ↓
git log -1 → Verify commit
  ↓
Re-run stress-test → PASS
  ↓
Mark task complete → DONE
```

**Time elapsed**: 2-5 minutes
**Commits made**: 1
**Lines changed**: 10-20
**Features added**: 0 (just fixed validation issues)

---

## 🎯 Your Mission

**Fix the minimum required to pass THIS gate. Nothing more. Nothing less.**

If you catch yourself thinking "I should also..." - STOP. That's not this gate's job.

Trust the pipeline. Other gates will catch other issues.

Your ONE job: Make THIS gate pass.
