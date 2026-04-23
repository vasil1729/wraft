## 2024-05-15 - [Elixir Authentication Timing Attack via Early Exit]
**Vulnerability:** Elixir `with` statements can short-circuit upon failed pattern matching (e.g., when `Account.find/1` returns an error or `nil` instead of `%User{}`). If this occurs before a computationally expensive operation like `Bcrypt.verify_pass/2` is reached, it introduces a significant timing difference between requests for valid and invalid emails. This allows attackers to enumerate registered users.

**Learning:** `with` and `cond` statements in authentication flows are dangerous when they skip expensive hashing functions on failed lookups. The hashing cost must be incurred consistently regardless of whether the user exists.

**Prevention:** Use nested `if` or `case` statements in authentication logic to ensure `Bcrypt.verify_pass/2` is evaluated exactly once when a user is found, and `Bcrypt.no_user_verify()` is explicitly called on the failure path when a user lookup returns nil or an error. This simulates the time delay and prevents timing-based enumeration. Always return a generic error message like `{:error, :invalid}` for both cases.
