## 2024-03-24 - Hardcoded LiveView Signing Salt
**Vulnerability:** Found hardcoded `live_view: [signing_salt: ...]` in `config/config.exs` which is checked into version control.
**Learning:** Phoenix defaults often put development secrets in `config.exs` which might be deployed if not overridden in `runtime.exs`.
**Prevention:** Ensure all secrets, including signing salts, are loaded from environment variables in `config/runtime.exs` and check for hardcoded secrets in base config files.
