## 2024-05-18 - Prevent User Enumeration and Timing Attacks in Elixir Login and Password Reset
**Vulnerability:** Elixir authentication flows (specifically `SessionController` and `UserController`) suffered from user enumeration via timing attacks and verbose error messages. The `SessionController` checked for deactivated users *before* password verification. The `UserController.signin` returned specific `{:error, :invalid_email}` messages that were translated into unique error responses by the `FallbackController`, while `UserController.generate_token` leaked email existence on error.
**Learning:** `with` statement short-circuiting on `nil` users can be used to enumerate users by observing response times (since the slow `Bcrypt.verify_pass` is skipped). Returning different errors for invalid email versus invalid password provides explicit user enumeration. Additionally, password reset flows should return a generic success message, regardless of whether the email exists, to prevent enumeration. Do NOT add `Bcrypt.no_user_verify()` to unhappy paths of the password reset flow to prevent DoS.
**Prevention:**
1. Execute `Bcrypt.no_user_verify()` on the unhappy path of password verification when a user is not found to normalize response times.
2. Evaluate business logic constraints (e.g. `is_deactivated`) *after* the password has been correctly verified.
3. Always return generic error tuples (e.g. `{:error, :invalid}`) that fallback to generic messages ("Invalid email or password").
4. Always return generic success on password reset endpoints regardless of user existence.
