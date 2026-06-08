## 2026-06-08 - Timing Attack and User Enumeration in Authentication
**Vulnerability:** The application was vulnerable to timing attacks and user enumeration in the login and password reset flows due to returning early on failed user lookups, and leaking user existence via responses.
**Learning:** Returning early on authentication failures without performing a dummy hash allows an attacker to enumerate valid emails based on response times. Furthermore, the password reset endpoint returned different responses based on whether an email existed.
**Prevention:** Always use `Bcrypt.no_user_verify()` on login authentication failure paths to equalize response times, and always return a generic 200 Success response from password reset endpoints regardless of user existence.
