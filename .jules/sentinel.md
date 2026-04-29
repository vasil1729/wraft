## 2024-05-24 - Elixir `with` statements short-circuiting on failed user lookups, leading to timing attacks
**Vulnerability:** User enumeration timing attack vulnerability in `SessionController`.
**Learning:** Using Elixir's `with` statement for authentication flows can inadvertently cause timing attacks. In the original `create/2` function of `SessionController`, when `InternalUsers.get_by_email` failed to match a user (or matched a deactivated user before checking the password), the `with` block would short-circuit. This skipped `Bcrypt.verify_pass`, leading to a measurable difference in response time compared to an existing user's login attempt. This timing discrepancy allows an attacker to enumerate valid email addresses and even active versus deactivated user statuses.
**Prevention:**
1. Use nested `if` statements instead of `with` statements to control the flow of authentication logic, ensuring computationally expensive operations like `Bcrypt.verify_pass` are evaluated exactly once.
2. For missing users, use `Bcrypt.no_user_verify()` to simulate the delay of `verify_pass`.
3. Verify passwords BEFORE evaluating account status variables like `is_deactivated`.