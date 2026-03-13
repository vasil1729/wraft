defmodule WraftDoc.Document.SecurityGanttTest do
  use WraftDoc.DataCase, async: false
  alias WraftDoc.Documents

  @moduletag :security

  describe "generate_gnu_gantt_chart security" do
    test "sanitizes filename and title to prevent command injection and path traversal" do
      # Setup malicious inputs
      # Filename attempts path traversal
      malicious_filename = "../../etc/passwd"
      # The title attempts to break out of quotes and execute system command
      # Corresponds to string: "; system("cat /etc/passwd"); "
      malicious_title = "\"; system(\"cat /etc/passwd\"); \""

      # Create a dummy CSV file for input
      File.mkdir_p("test/fixtures")
      File.write("test/fixtures/security_test.csv", "Time,Label\n2023-01-01,Task 1")

      input = %Plug.Upload{
        filename: malicious_filename,
        path: "test/fixtures/security_test.csv"
      }

      # Execute the function
      try do
        Documents.generate_tex_chart(%{
          "input" => input,
          "btype" => "gantt",
          "name" => malicious_title
        })
      rescue
        e in ErlangError ->
          # If gnuplot is missing, System.cmd raises :enoent.
          # We can still verify the script generation logic.
          if e.original == :enoent do
            verify_script_content()
          else
            reraise e, __STACKTRACE__
          end
      else
        _ -> verify_script_content()
      end
    end

    defp verify_script_content do
      script_content = File.read!("temp/gantt_script.plt")

      # Verify title is escaped.
      # The generated script should have title inside quotes, with inner quotes escaped.
      # set title "\"; system(\"cat /etc/passwd\"); \""

      # We verify that quotes are escaped
      assert script_content =~ ~s|\\"; system(\\"cat|

      # Verify filename is sanitized (no ../..)
      # dest_path should be temp/gantt_chart_input/passwd (basename of ../../etc/passwd)
      # And it should be used in plot command
      assert script_content =~ "temp/gantt_chart_input/passwd"
      refute script_content =~ "../../etc/passwd"
    end
  end
end
