## 2025-02-28 - Missing BCrypt Double-Hashing Delay on Invalid User Lookups
**Vulnerability:** In Elixir authentication flows (like `UserController.signin` and `SessionController.create`), short-circuiting `with` statements upon failed user lookups (`Account.find/1`) or `nil` users can cause a timing leak, which could lead to user enumeration.
**Learning:** Elixir pattern-matching/with-statement implicit failures skip the slow `Bcrypt.verify_pass/2` function, returning immediately, thus verifying if the username exists in less time than if it does exist.
**Prevention:** Explicitly handle `nil` or `{:error, :invalid_email}` users with `Bcrypt.no_user_verify()` to simulate the delay of `Bcrypt.verify_pass/2`. Ensure it handles edge cases returning generic errors so enumeration fails.
