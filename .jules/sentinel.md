## 2024-03-14 - Stop User Enumeration via Timing Leak
**Vulnerability:** User enumeration via timing attack in login endpoints.
**Learning:** In Elixir, when a `with` statement fails at a user lookup (e.g., `get_user_by_email`), it falls through directly and bypasses `Bcrypt.verify_pass`. Because bcrypt password hashing takes significant time (hundreds of milliseconds), returning early allows an attacker to measure response times and discern whether an email exists in the database.
**Prevention:** In authentication code, whenever user lookup fails or auth fails generally, always call `Bcrypt.no_user_verify()` to simulate the time delay of hashing a password.
