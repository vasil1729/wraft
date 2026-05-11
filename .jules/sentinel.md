
## 2024-05-11 - Timing attack user enumeration via early exits
**Vulnerability:** User enumeration vulnerability using timing attacks. The authentication endpoints skipped calling Bcrypt.verify_pass entirely if the user look-up failed, taking significantly less time compared to when the user was found.
**Learning:** `with` structures that exit early bypass later costly operations. This is a common pattern for writing Elixir code to be concise and handle `nil` values efficiently, but it is dangerous in authentication flows.
**Prevention:** Uncouple the user lookup from the password validation. If the lookup fails, use dummy hashing `Bcrypt.no_user_verify()`. If the lookup succeeds, verify the password immediately *before* checking account-specific flags (e.g. `is_deactivated`). Use explicit `if` / `case` structures rather than `with` to guarantee proper execution paths.
