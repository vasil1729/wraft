defmodule WraftDoc.Document.SecurityGanttTest do
  use WraftDoc.DataCase, async: false
  alias WraftDoc.Documents

  @moduletag :security

  describe "generate_tex_chart/1 security" do
    test "reproduce command injection in generate_gnu_gantt_chart" do
      # Setup a dummy input file
      input_file = "temp/gantt_chart_input/test_input.csv"
      File.mkdir_p!("temp/gantt_chart_input")
      File.write!(input_file, "dummy data")

      # Define the injected command
      # This command tries to create a file 'injected.txt' in the temp directory
      injected_file = "temp/injected.txt"
      # Clean up previous runs
      File.rm(injected_file)

      # The injection payload:
      # The original script does: set title "//title//"
      # We inject: "title"; system "touch temp/injected.txt"; set title "
      # This results in: set title "title"; system "touch temp/injected.txt"; set title ""
      # Gnuplot supports 'system' command to execute shell commands.
      payload = "title\"; system \"touch #{injected_file}\"; set title \""

      params = %{
        "input" => %Plug.Upload{filename: "test_input.csv", path: input_file},
        "btype" => "gantt",
        "name" => payload
      }

      # Run the function
      try do
        Documents.generate_tex_chart(params)
      rescue
        _ -> :ok # Ignore errors, we just check side effects
      end

      # Verify if the injected file exists
      refute File.exists?(injected_file), "Vulnerability fixed: Command injection blocked, 'injected.txt' was NOT created."

      # Cleanup
      File.rm(input_file)
    end
  end
end
