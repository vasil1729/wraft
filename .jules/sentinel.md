## 2024-04-21 - [Authentication Timing Attacks]
**Vulnerability:** Early exits in Elixir 'with' statements during user lookup and status checks allowed enumeration of valid emails and deactivated accounts via timing differences.
**Learning:** 'Bcrypt.no_user_verify()' must be explicitly called on failure paths where a user is not found to simulate password hashing time. Status checks like 'is_deactivated' must happen only *after* password verification.
**Prevention:** Use nested 'case' or 'if' statements instead of 'with' blocks for authentication to guarantee that a computationally expensive operation is evaluated exactly once regardless of user existence.
