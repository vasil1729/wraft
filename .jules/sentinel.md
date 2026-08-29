## 2024-05-24 - Prevent User Enumeration and Timing Attacks in Auth Flow
**Vulnerability:** The authentication flow leaked user existence through different error responses (`{:error, :invalid_email}` vs generic error) and a lack of timing equality (bypassing `Bcrypt` validation when user is not found or inputs are missing).
**Learning:** When inputs are invalid, return standard generic errors before user lookups to prevent enumeration via empty input. Ensure `Bcrypt.no_user_verify()` is triggered during any user lookup failure.
**Prevention:** Always extract user lookups into a defensive case statement, return `{:error, :invalid}` on failure, and explicitly validate empty inputs to `{:error, :no_data}` before lookup.
