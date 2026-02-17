defmodule WraftDoc.SecurityGanttTest do
  use WraftDoc.DataCase, async: true
  alias WraftDoc.Documents

  describe "Gnuplot sanitization" do
    test "sanitize_gnuplot_string/1 escapes backslashes, double quotes, and backticks" do
      assert Documents.sanitize_gnuplot_string("normal string") == "normal string"
      assert Documents.sanitize_gnuplot_string("string with \"quotes\"") == "string with \\\"quotes\\\""
      assert Documents.sanitize_gnuplot_string("string with \\backslash") == "string with \\\\backslash"
      assert Documents.sanitize_gnuplot_string("injection\"; system(\"ls\"); \"") == "injection\\\"; system(\\\"ls\\\"); \\\""
      # Backtick injection
      assert Documents.sanitize_gnuplot_string("string with `backticks`") == "string with \\`backticks\\`"
    end

    test "sanitize_gnuplot_path/1 escapes single quotes" do
      assert Documents.sanitize_gnuplot_path("/path/to/file") == "/path/to/file"
      assert Documents.sanitize_gnuplot_path("/path/with/'quote") == "/path/with/''quote"
    end
  end
end
