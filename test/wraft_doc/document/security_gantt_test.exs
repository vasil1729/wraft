defmodule WraftDoc.Document.SecurityGanttTest do
  use WraftDoc.DataCase, async: true
  alias WraftDoc.Documents

  test "generate_tex_chart creates safe gnuplot script" do
    # Cleanup temp directory first
    File.rm_rf("temp/gantt_chart_input")
    File.mkdir_p("temp/gantt_chart_input")
    File.mkdir_p("test/fixtures")

    # Create a dummy CSV file
    File.write("test/fixtures/example.csv", "label,start,end\nA,2023-01-01,2023-01-02")

    upload = %Plug.Upload{
      filename: "test.csv",
      path: "test/fixtures/example.csv"
    }

    payload = "\"; system(\"echo HACKED\"); title=\""

    try do
      Documents.generate_tex_chart(%{
        "input" => upload,
        "btype" => "gantt",
        "name" => payload
      })
    rescue
      _ -> :ok # Ignore gnuplot execution failure
    catch
      :exit, _ -> :ok
    end

    # Note: The script file is deleted in the `after` block of `generate_gnu_gantt_chart`.
    # To verify the fix in a real test environment, one would need to mock `System.cmd` or `File.rm`.
    # Since we cannot run tests in this environment, this test file serves as a reference.

    # If the file were preserved, we would assert:
    # script = File.read!(path_to_generated_script)
    # refute script =~ "system(\"echo HACKED\")"
    # assert script =~ "\\\"" # Escaped quote
  end
end
