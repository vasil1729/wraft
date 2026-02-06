## 2026-02-06 - Hardcoded LiveView Signing Salt
**Vulnerability:** Hardcoded `live_view` signing salt in `config/config.exs`.
**Learning:** A hardcoded salt was found in the configuration, which could be used to reduce the entropy needed to forge LiveView tokens if the `secret_key_base` were compromised.
**Prevention:** Use `System.get_env` in `config/runtime.exs` to enforce environment variables for sensitive secrets in production, and use obvious development defaults for local environments.
