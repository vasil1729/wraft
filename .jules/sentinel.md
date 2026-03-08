## 2024-03-08 - [CRITICAL] OS Command Injection and Path Traversal in Gnuplot Gantt Chart Generation
**Vulnerability:** The `generate_gnu_gantt_chart/2` function was vulnerable to multiple issues: OS Command injection (since Gnuplot scripts execute system commands and inputs weren't properly sanitized/escaped before being substituted into the `.plt` template), Path Traversal (using an unsanitized `filename` directly in a path, allowing arbitrary file overwrites), Race Conditions (hardcoded temporary file paths across concurrent requests), and Disk Space Exhaustion (failing to clean up temporary files).
**Learning:** Gnuplot template substitutions act like OS command injection if variables aren't strictly escaped, as malicious payloads can break out of string literals or inject newlines to execute commands within the `.plt` file. Furthermore, user uploads require strict path sanitization (like `Path.basename/1`) and concurrency controls (like unique UUID-based temp directories) to operate securely.
**Prevention:**
- Always escape string variables passed into `.plt` files (escaping backslashes, quotes, backticks, and stripping newlines).
- Always use `Path.basename/1` and restrict character sets for uploaded filenames.
- Use `Ecto.UUID.generate()` with `System.tmp_dir!()` to isolate temporary files.
- Always implement `try/after` blocks to ensure temporary files are cleaned up even if script execution fails.
