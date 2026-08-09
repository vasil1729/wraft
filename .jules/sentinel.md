## 2024-05-24 - Fix User Enumeration via Fallback Controller
**Vulnerability:** The authentication flow leaked user existence due to returning specific error tuples (like `{:error, :invalid_email}`) which the FallbackController mapped to a specific error message, and a missing `Bcrypt.no_user_verify()` check for invalid users.
**Learning:** In Elixir `with` statement authentication flows, early exits for non-existent users allow enumeration via response times and messages. We must ensure timing consistency and mask lookup failures before the FallbackController.
**Prevention:** Extract user lookups into a `case` statement, trigger `Bcrypt.no_user_verify()` on failure, and map all missing user errors to generic invalid credential errors (`{:error, :invalid}`).
