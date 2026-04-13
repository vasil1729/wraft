## 2024-05-24 - Account Enumeration via Deactivation Checks
**Vulnerability:** An attacker could enumerate valid internal accounts by guessing emails and checking if the response returned "Your account has been deactivated" instead of a generic login error, because the `is_deactivated` check happened in a `with` statement *before* password verification.
**Learning:** Checking business logic flags (like account suspension/deactivation) before verifying the password leaks account existence and status to unauthenticated users.
**Prevention:** Always verify the user's password (`Bcrypt.verify_pass`) *before* checking account status flags like `is_deactivated` to ensure only authenticated users can learn about account statuses.
