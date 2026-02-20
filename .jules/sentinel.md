# Sentinel Journal

## 2025-05-23 - Hardcoded LiveView Signing Salt
**Vulnerability:** Found a hardcoded `signing_salt` for Phoenix LiveView in `config/config.exs`. This value is used to sign and verify LiveView connections. If exposed, an attacker could potentially forge connection tokens.
**Learning:** Configuration files committed to version control often contain default values that end up being used in production if not explicitly overridden.
**Prevention:** Always use `System.get_env/1` in `config/runtime.exs` for sensitive values. Enforce environment variable presence in production.
