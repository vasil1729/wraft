## 2024-04-05 - [Timing Attack and Enumeration Fixes]
**Vulnerability:** User enumeration via timing attacks during login, and explicit enumeration during password resets.
**Learning:** Checking business logic (`is_deactivated`) before password verification allows attackers to enumerate active vs. deactivated accounts. Returning specific `{:error, :invalid_email}` directly to the API leaks which emails exist. Using `Bcrypt.no_user_verify()` is crucial on failure paths to prevent timing gaps.
**Prevention:** Always verify passwords before other logic in authentication flows. Add `Bcrypt.no_user_verify()` delays on user not found, and return generic `200 OK` responses for password resets even if the email doesn't exist.
