## 2025-05-27 - Command Injection via Gnuplot Script Generation
**Vulnerability:** Found a Command Injection and Path Traversal vulnerability in `Documents.generate_gnu_gantt_chart/2`. The function interpolated user-controlled `title` directly into a Gnuplot script file and executed it via `System.cmd("gnuplot", ...)`. It also used unsanitized `filename` in a `System.cmd("cp", ...)` call allowing path traversal.
**Learning:** Even if `System.cmd` is used safely (avoiding shell), the *content* of the file being processed by the command might be vulnerable to injection if constructed from user input. Always sanitize data written to script files or config files that are subsequently executed or parsed by other tools.
**Prevention:**
1.  Use generated IDs (UUIDs) for temporary filenames instead of user input.
2.  Sanitize any user input written to files that are interpreted as code/scripts.
3.  Use `File.cp!` instead of `System.cmd("cp", ...)` for safer file operations.
4.  Verify file paths actually exist; the original code pointed to a non-existent template path.
