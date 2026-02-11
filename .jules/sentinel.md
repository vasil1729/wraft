## 2026-02-11 - Hardcoded LiveView Signing Salt
**Vulnerability:** LiveView signing salt was hardcoded in `config/config.exs`, making it the default for all environments including production if not explicitly overridden.
**Learning:** Shared configuration files (`config.exs`) should never contain secrets, even as defaults, because they can easily be overlooked during deployment or environment setup.
**Prevention:** Always use `System.get_env` in `config/runtime.exs` for secrets, and fail securely (raise an error) if the secret is missing in production. Use separate `dev.exs` and `test.exs` for non-sensitive defaults.
