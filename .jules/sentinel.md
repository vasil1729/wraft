
## 2024-03-12 - Fix timing attacks and user enumeration via error responses
**Vulnerability:** User enumeration via both timing differences and explicit error messages.
**Learning:** Elixir's `with` statement short-circuits on failure. During authentication, if the user lookup fails, the password hashing step is skipped, revealing that the email doesn't exist via faster response times. Also, using distinct error messages/codes (e.g. `invalid_email` vs `invalid_password`) lets attackers definitively know which emails exist.
**Prevention:**
1. Always catch the short-circuited `{:error, :invalid_email}` in the `else` block of a `with` statement and explicitly call `Bcrypt.no_user_verify()` to simulate the delay of hashing a password before returning a generic error.
2. Ensure generic fallback controllers handle all authentication-related failures with the exact same JSON response and HTTP status code.
