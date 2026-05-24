## 2024-05-24 - [Timing Attack in Login]
**Vulnerability:** Timing attack allowing user enumeration based on early exits for deactivated accounts and unknown emails in SessionController and UserController.
**Learning:** Checking business logic flags (like `is_deactivated`) *before* verifying the password, or returning early when an email isn't found without a delay, allows attackers to guess valid usernames and their statuses by measuring response times.
**Prevention:** Always verify passwords before checking business logic status flags. When an email is not found, use `Bcrypt.no_user_verify()` to simulate the delay of password hashing.
