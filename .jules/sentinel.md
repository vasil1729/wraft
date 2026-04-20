## 2024-05-24 - [Fix Authentication Timing Attack in SessionController]
**Vulnerability:** User enumeration timing attack in Admin authentication flow. The `with` statement short-circuited when an email wasn't found or an account was deactivated, skipping the expensive `Bcrypt.verify_pass` check.
**Learning:** Early exits before performing computationally expensive operations (like password hashing) leak information about account existence and status via response time differences.
**Prevention:** Use nested `if` statements instead of `with` or `cond` in auth flows to ensure `Bcrypt.verify_pass` (or `Bcrypt.no_user_verify()`) runs exactly once for both valid and invalid email lookups, and always check password validity before checking account status flags like `is_deactivated`.
