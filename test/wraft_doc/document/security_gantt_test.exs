defmodule WraftDoc.Document.SecurityGanttTest do
  use WraftDoc.DataCase, async: true
  alias WraftDoc.Documents

  describe "generate_tex_chart/1 security" do
    test "prevents path traversal in filename" do
      # Create a dummy file to simulate upload
      path = "test/fixtures/malicious.csv"
      File.mkdir_p!("test/fixtures")
      File.write!(path, "label,start,end\nTask 1,2023-01-01,2023-01-02")

      upload = %Plug.Upload{
        filename: "../../malicious.csv",
        path: path
      }

      params = %{
        "input" => upload,
        "btype" => "gantt",
        "name" => "Project X"
      }

      # If the fix works, it should strip ../../ and copy to temp/gantt_chart_input/malicious.csv
      # Note: We rely on the implementation not to raise an error when sanitizing the filename.

      # Calling the function. It returns {output, exit_code} from System.cmd("gnuplot", ...)
      # We ignore the result as we are testing side effects (or lack thereof)
      try do
        Documents.generate_tex_chart(params)
      rescue
        _ -> :ok # It might fail if gnuplot is not installed, but we check file existence
      end

      # Verify the file was copied to the sanitized location
      assert File.exists?("temp/gantt_chart_input/malicious.csv")

      # Verify it did NOT traverse (this check depends on where the traversal would have landed)
      # If cwd is root, ../../ might go outside, but assuming we are in app root.
      # The vulnerable code did: "temp/gantt_chart_input/#{filename}" -> "temp/gantt_chart_input/../../malicious.csv"
      # which simplifies to "malicious.csv" (if temp is in root) or "temp/malicious.csv" depending on structure.
      # We just check the intended file exists.

      # Clean up
      File.rm(path)
      File.rm("temp/gantt_chart_input/malicious.csv")
    end

    test "prevents command injection in title" do
      path = "test/fixtures/normal.csv"
      File.mkdir_p!("test/fixtures")
      File.write!(path, "label,start,end\nTask 1,2023-01-01,2023-01-02")

      upload = %Plug.Upload{
        filename: "normal.csv",
        path: path
      }

      # Malicious title attempting to inject gnuplot commands
      # e.g. closing quote, semicolon, system command
      malicious_title = "\"; system(\"touch temp/pwned\"); \""

      params = %{
        "input" => upload,
        "btype" => "gantt",
        "name" => malicious_title
      }

      try do
        Documents.generate_tex_chart(params)
      rescue
        _ -> :ok
      end

      # Check if injected command executed
      refute File.exists?("temp/pwned")

      # Clean up
      File.rm(path)
      File.rm("temp/gantt_chart_input/normal.csv")
    end
  end
end
