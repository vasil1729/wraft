## 2024-05-13 - [Timing Attack & User Enumeration]
**Vulnerability:** The authentication endpoint allows user enumeration via a timing attack and direct error messages, by using `Account.find/1` and only validating passwords for existing users while returning different error tuples.
**Learning:** Returning early or passing lookup errors directly bypasses hashing time or gives explicit failure reasons, allowing attackers to check if accounts exist.
**Prevention:** Extract lookups into defensive case statements, run `Bcrypt.no_user_verify()` on failure paths to equalize response times, and explicitly map all lookup errors to generic `{:error, :invalid}` before passing to the `with` block and FallbackController.
