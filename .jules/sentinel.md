## 2024-05-23 - Gnuplot Command Injection via Script Template
**Vulnerability:** Found Remote Code Execution (RCE) vulnerability in `generate_gnu_gantt_chart` where user input (title) was interpolated directly into a Gnuplot script template without sanitization. Also found Path Traversal and Race Condition issues due to using user-provided filenames and static temporary file paths.
**Learning:** Gnuplot scripts are executable code. String interpolation into executable scripts is equivalent to `eval()`. Also, relying on external binaries like `gnuplot` via `System.cmd` requires careful handling of inputs and intermediate files.
**Prevention:**
1. Use UUIDs for temporary filenames to prevent collisions and traversal.
2. Sanitize all user inputs before injecting into templates (escape quotes, backslashes).
3. Use safer alternatives to shell commands (e.g., `File.cp!` instead of `System.cmd("cp")`).
