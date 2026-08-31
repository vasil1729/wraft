## 2024-05-24 - Prevent timing attacks in Admin Auth
**Vulnerability:** The admin login flow checked account status (`is_deactivated: false`) during the user lookup and immediately returned an error for deactivated accounts without hashing the password. Also, missing users did not trigger a dummy hash.
**Learning:** Early returns on account status or missing users without evaluating `Bcrypt` create timing discrepancies, allowing attackers to enumerate emails and discover deactivated accounts.
**Prevention:** Always extract the user lookup, run `Bcrypt.no_user_verify()` for non-existent users, and evaluate `Bcrypt.verify_pass/2` before checking account status flags like `is_deactivated`.
