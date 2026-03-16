## 2024-05-24 - [Avoid Timing Leaks in Elixir with Statements]
**Vulnerability:** User enumeration via timing attacks in authentication endpoints.
**Learning:** In Elixir authentication flows, short-circuiting `with` statements upon failed user lookups can cause timing leaks because the password hashing delay is skipped.
**Prevention:** Explicitly call `Bcrypt.no_user_verify()` on these specific failure paths (e.g., `nil` or `{:error, :invalid_email}`) to simulate password hashing delays. Return generic error messages to avoid information leakage.
