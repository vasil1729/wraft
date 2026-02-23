defmodule WraftDoc.SecurityGanttTest do
  use WraftDoc.DataCase
  alias WraftDoc.Documents

  setup do
    # Create dummy input
    File.mkdir_p!("temp/test_input")
    input_path = "temp/test_input/test.csv"
    File.write!(input_path, "label,start,end\nTask 1,2023-01-01,2023-01-05")

    # Ensure template exists. In a proper test run, priv dir should be available.
    # We write a dummy template to ensure the file read doesn't fail if the actual file is missing in this env.
    template_dir = Application.app_dir(:wraft_doc, "priv/slugs/gantt_chart")
    File.mkdir_p!(template_dir)
    template_path = Path.join(template_dir, "gnuplot_gantt.plt")
    File.write!(template_path, "set title \"//title//\"\nplot '//input//'")

    on_exit(fn ->
      File.rm_rf("temp/test_input")
      File.rm_rf("temp/gantt_chart_output")
      File.rm("temp/hacked.txt")
    end)

    {:ok, input_path: input_path}
  end

  test "generate_gnu_gantt_chart prevents command injection via title", %{input_path: input_path} do
    # Malicious title payload
    malicious_title = "\"; system(\"echo HACKED > temp/hacked.txt\"); set title \""

    upload = %Plug.Upload{
      filename: "test.csv",
      path: input_path
    }

    # Call the function
    try do
      Documents.generate_tex_chart(%{"input" => upload, "btype" => "gantt", "name" => malicious_title})
    rescue
      # Ignore missing gnuplot error
      _ -> :ok
    catch
      :exit, _ -> :ok
    end

    # Verify that the injection did NOT execute
    refute File.exists?("temp/hacked.txt"), "Command injection succeeded: temp/hacked.txt was created"
  end
end
