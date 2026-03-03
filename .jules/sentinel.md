## 2025-02-19 - [User Enumeration Prevention]
**Vulnerability:** User enumeration via timing attack and specific error messages on login.
**Learning:** Checking for user existence (`Account.find`) before verifying password allows attackers to differentiate valid vs invalid emails via response time (no bcrypt delay) and error messages (invalid email vs invalid password).
**Prevention:** Always perform a constant-time password verification (using `Bcrypt.no_user_verify()` if user missing) and return generic error messages for both cases. Consolidated logic into `Account.authenticate_by_email_and_password/2`.
