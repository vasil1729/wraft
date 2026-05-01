## 2026-05-01 - Prevent User Enumeration via Timing Attacks in Elixir with Statements
**Vulnerability:** Elixir's `with` statement short-circuits on failure. In authentication flows, if a user lookup failed (e.g., email not found), the `with` statement skipped the computationally expensive `Bcrypt.verify_pass/2`. This created a measurable timing difference, allowing an attacker to enumerate valid email addresses based on response times. Additionally, account status (`is_deactivated`) was checked before password verification, allowing enumeration of account statuses. Finally, password reset endpoints leaked email existence by returning different responses based on user lookup success.
**Learning:** `with` statements are unsafe for authentication logic if the "unhappy path" skips expensive operations. Status checks must occur *after* password verification to prevent status enumeration. Public-facing flows like password resets must always return a generic success response regardless of backend processing.
**Prevention:**
1. Avoid `with` statements for password verification flows; prefer nested `if` or `case` statements.
2. Explicitly call `Bcrypt.no_user_verify()` on the unhappy path (e.g., when a user is not found) to simulate hashing time. Do not call it if password verification simply fails.
3. Verify passwords *before* checking business logic status flags like `is_deactivated`.
4. Ensure public token generation/reset endpoints return identical generic HTTP 200 OK responses regardless of input validity.
