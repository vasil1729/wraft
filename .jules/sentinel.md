## 2024-05-15 - [Auth Timing Attacks & DoS Risks]
**Vulnerability:** Elixir authentication flows with early exit `with` statements create timing vulnerabilities. Furthermore, computing bcrypt hashes on password reset failure paths leads to DoS.
**Learning:** `Bcrypt.no_user_verify()` is necessary for mitigating user enumeration via timing attacks in login flows but using it on password reset forms can introduce DoS vectors.
**Prevention:** Avoid `with` logic for expensive operations, preferring nested `if` statements so the expensive logic is guaranteed to be executed.
