## 2025-05-20 - Command Injection in Gnuplot Generation
**Vulnerability:** A command injection vulnerability was identified in `generate_gnu_gantt_chart/2`. User-supplied `title` was interpolated directly into a Gnuplot script string without escaping. This could allow execution of arbitrary shell commands via the Gnuplot `system()` command.
**Learning:** The code treated the script as a simple template but failed to sanitize inputs that became code (Gnuplot commands). It also used predictable temporary paths (`temp/gantt_chart_input/filename.csv`), creating race conditions and potential path traversal/file overwrite risks. The path to the template file was also incorrect (`lib/priv/...` vs `priv/slugs/...`), indicating lack of testing for this feature.
**Prevention:**
1. Always escape user input when interpolating into any interpreted language (SQL, shell, Gnuplot, etc.).
2. Use `Ecto.UUID` to generate unique working directories/filenames for temporary operations to prevent race conditions and collisions.
3. Use `Application.app_dir` or `:code.priv_dir` to locate application resources reliably.
4. Prefer language-native file operations (`File.cp!`) over shell commands (`System.cmd("cp", ...)`).
