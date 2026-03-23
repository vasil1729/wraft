## 2026-03-23 - [Timing leak and user enumeration via authentication error handling]
**Vulnerability:** In Elixir authentication, matching against user properties (like is_deactivated) before checking the password or bypassing password verification when an email doesn't exist exposes user enumeration via timing attacks.
**Learning:** Short-circuiting authentication steps skips the heavy Bcrypt hashing. Therefore, an attacker can observe response times to deduce if an email exists and is deactivated.
**Prevention:** Always verify the password first if the user exists. If the user does not exist, explicitly call Bcrypt.no_user_verify() to simulate the hashing delay and always return generic error messages.
