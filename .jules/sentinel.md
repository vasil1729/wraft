## 2024-05-22 - [Path Traversal and Command Injection via Unsanitized Input in Gnuplot]
**Vulnerability:** Found Path Traversal in file upload handling (via `filename`) and Command Injection potential in Gnuplot script generation (via `title`).
**Learning:** `System.cmd` usage for simple file operations like `cp` introduces unnecessary shell risks and platform dependency. Relative paths for `priv` resources are brittle; `:code.priv_dir` should always be used.
**Prevention:** Always sanitize user inputs used in file paths (`Path.basename`) and shell commands. Use Elixir native `File` module instead of shelling out. Use strict allow-lists for inputs used in generated scripts.
