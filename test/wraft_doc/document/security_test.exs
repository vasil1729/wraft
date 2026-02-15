defmodule WraftDoc.DocumentSecurityTest do
  use WraftDoc.DataCase, async: true
  alias WraftDoc.Documents

  describe "generate_tex_chart/1 security" do
    test "prevents path traversal in filename" do
      # Create a dummy file to simulate upload
      upload_path = "test/fixtures/upload_test.txt"
      # Ensure fixtures dir exists
      File.mkdir_p!("test/fixtures")
      File.write!(upload_path, "test content")

      upload = %Plug.Upload{
        path: upload_path,
        filename: "../../../../../tmp/traversal_test_file"
      }

      params = %{
        "input" => upload,
        "btype" => "gantt",
        "name" => "security_test"
      }

      # We expect the function to proceed (it might fail later due to missing gnuplot script),
      # but the key is that the file is copied to the SAFE location.

      try do
        Documents.generate_tex_chart(params)
      rescue
        _ -> :ok # Ignore subsequent errors (gnuplot missing etc)
      end

      # Check that the traversal path was NOT created
      refute File.exists?("/tmp/traversal_test_file"), "Path traversal vulnerability exploited! File written to /tmp/traversal_test_file"

      # Check that the sanitized path WAS created
      # filename should be just "traversal_test_file"
      sanitized_path = "temp/gantt_chart_input/traversal_test_file"
      assert File.exists?(sanitized_path), "File should have been copied to sanitized path: #{sanitized_path}"

      # Cleanup
      File.rm(upload_path)
      File.rm(sanitized_path)
      File.rm("/tmp/traversal_test_file")
    end
  end
end
