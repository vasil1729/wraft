## 2024-05-24 - [Timing Attack in Elixir Authentication Flows]
**Vulnerability:** Timing attack allowing attackers to enumerate existing emails and check account statuses (e.g., deactivated vs active) by measuring server response times.
**Learning:** Using Elixir's `with` statement in authentication controllers (e.g., `SessionController`) can cause operations to short-circuit upon a failed condition. For instance, if an email isn't found or an account is deactivated, `with` jumps directly to the `else` block, skipping the computationally expensive password hashing process (`Bcrypt.verify_pass`). This creates a significant timing difference compared to a valid login.
**Prevention:**
1. Replace `with` logic with nested `if/case` logic in authentication flows.
2. In the branch where a user is *not* found, explicitly call `Bcrypt.no_user_verify()` to simulate the hashing delay.
3. Check business logic flags (like `is_deactivated`) only *after* password verification so an attacker cannot enumerate statuses by simply supplying the correct email but wrong password.
