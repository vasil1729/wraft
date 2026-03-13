## 2025-02-12 - Hardcoded LiveView Signing Salt
**Vulnerability:** Found a hardcoded `signing_salt` for `live_view` configuration in `config/config.exs`, which is used to sign/verify LiveView tokens.
**Learning:** Default configurations or boilerplate code often hardcode secrets for convenience, which can be overlooked when deploying to production.
**Prevention:** Ensure all secrets (salts, keys, passwords) are loaded from environment variables in `config/runtime.exs` and raise an error if missing in production.
