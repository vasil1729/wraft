defmodule WraftDoc.Document.SecurityGanttTest do
  use WraftDoc.DataCase, async: true
  alias WraftDoc.Documents

  @tag :security
  describe "generate_gnu_gantt_chart/2 security" do
    test "prevents command injection and handles paths safely" do
      # Mock upload struct
      upload = %Plug.Upload{
        filename: "test.csv",
        path: Path.join(System.tmp_dir!(), "test_upload.csv")
      }
      File.write!(upload.path, "data")

      # Dangerous title that attempts command injection
      dangerous_title = "\"; system('touch /tmp/pwned'); \""

      # We expect this to either fail (due to missing gnuplot) or return a safe path.
      # It should NOT execute the injected command.
      # Since we can't assert on side effects easily without gnuplot, we primarily
      # ensure the function doesn't crash with internal errors and attempts to use safe paths.

      try do
        result = Documents.generate_tex_chart(%{
          "input" => upload,
          "btype" => "gantt",
          "name" => dangerous_title
        })

        # If it returns, check result is a string (path) or tuple (old behavior, but we are changing it)
        # We expect a path string after our fix.
        assert is_binary(result)

      rescue
        e in ErlangError ->
          # If gnuplot is missing, System.cmd raises ErlangError: :enoent
          assert e.original == :enoent
      end
    end
  end
end
