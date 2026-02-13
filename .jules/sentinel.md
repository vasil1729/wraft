## 2025-02-13 - User Enumeration via Timing Attack
**Vulnerability:** Timing Attack on Login Endpoint
**Learning:** `Account.find` (fast DB query) ran before `Account.authenticate` (slow hash), allowing attackers to guess valid emails by measuring response time.
**Prevention:** Always verify password (or dummy verification via `Bcrypt.no_user_verify()`) regardless of user existence. Use a single function for lookup and auth.
