## 2024-05-24 - Prevent user enumeration and timing attacks in authentication flow
**Vulnerability:** The authentication flow leaked user existence via missing generic error normalization and skipped bcrypt hashing for non-existent users, allowing timing and enumeration attacks.
**Learning:** Returning early or omitting bcrypt checks for missing users (or empty inputs) creates discrepancies. Relying on implicit fallthrough without explicit `else` blocks can leak specific errors.
**Prevention:** Always extract user lookups into a defensive case statement, trigger `Bcrypt.no_user_verify()` on failure, validate inputs upfront with generic errors, and use explicit `else` fallbacks to normalize output.
