defmodule WraftDocWeb.PropicUploader do
  @moduledoc false
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original]
  @extension_whitelist ~w(.jpg .jpeg .gif .png)

  # Validate Filetype
  def validate({file, _}) do
    file_extension =
      file.file_name
      |> Path.extname()
      |> String.downcase()

    Enum.member?(@extension_whitelist, file_extension)
  end

  # Change Filename
  def filename(_version, {_file, user}) do
    "profilepic_#{user.name}"
  end

  # Storage Directory
  def storage_dir(_, {_file, user}) do
    "uploads/avatars/#{user.id}"
  end
end
