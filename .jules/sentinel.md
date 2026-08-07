## Sentinel Journal
## 2026-08-07 - Prevent Timing Attacks and User Enumeration in Elixir Authentication
**Vulnerability:** User enumeration in login flow due to inconsistent error messages (`{:error, :invalid_email}` vs `{:error, :invalid}`) and missing artificial hashing delay (timing attack) for non-existent users.
**Learning:** In Elixir with `bcrypt_elixir`, placing `Bcrypt.verify_pass/2` inside a `with` block after an `Account.find/1` lookup exposes user existence, because missing users skip the slow hash verification step and return distinct errors.
**Prevention:** Extract user lookups into explicit `case` statements before `with` blocks. On failure, invoke `Bcrypt.no_user_verify()` to mimic hash timing and strictly return generic errors (e.g. `{:error, :invalid}`) to the FallbackController.
