## 2026-05-13 - [Timing Attacks in Authentication Flows]
**Vulnerability:** Timing attack via early return in `with` statements during user authentication.
**Learning:** In Elixir authentication flows, short-circuiting `with` statements upon failed user lookups can cause timing leaks. If the slow password hashing operation (`Bcrypt.verify_pass()`) is skipped when a user is not found, attackers can enumerate valid emails by measuring response times.
**Prevention:** Use explicit nested `if` or `case` statements to handle nil users. Ensure `Bcrypt.no_user_verify()` is explicitly called on the failure path (e.g., `nil` or `{:error, :invalid_email}`) to simulate password hashing delays. Never call it if the user is found but password verification fails, to avoid double-hashing vulnerabilities.
