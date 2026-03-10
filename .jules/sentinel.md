# Sentinel Journal - Critical Security Learnings

## 2025-05-15 - [CRITICAL] Path Traversal in File Uploads
**Vulnerability:** Found `System.cmd("cp", ...)` using unsanitized `filename` from `Plug.Upload` in `WraftDoc.Documents.generate_gnu_gantt_chart` and `insert_bulk_build_work`. This allowed attackers to write uploaded files to arbitrary locations on the server (Path Traversal).
**Learning:** `Plug.Upload` filename is user-controlled and can contain `../` sequences. Trusting it blindly in filesystem operations is dangerous. Also, using `System.cmd("cp")` is less secure and robust than Elixir's `File` module.
**Prevention:** Always sanitize filenames using `Path.basename/1` before using them. Prefer `File.cp!/2` over shelling out to `cp`.
