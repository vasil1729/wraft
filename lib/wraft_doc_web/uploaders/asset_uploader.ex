defmodule WraftDocWeb.AssetUploader do
  @moduledoc false
  use Waffle.Definition
  use Waffle.Ecto.Definition

  alias WraftDoc.Client.Minio
  alias WraftDoc.Document.Asset

  @versions [:original]
  @font_style_name ~w(Regular Italic Bold BoldItalic)

  # To add a thumbnail version:
  # @versions [:original, :thumb]

  # Override the bucket on a per definition basis:
  # def bucket do
  #   :custom_bucket_name
  # end

  # Whitelist file extensions:
  def validate({file, %Asset{type: "layout"}}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()

    if ".pdf" == file_extension, do: :ok, else: {:error, "invalid file type"}
  end

  def validate({file, %Asset{type: "theme"}}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()

    case Enum.member?(~w(.otf .ttf), file_extension) && check_file_naming(file.file_name) do
      true -> :ok
      false -> {:error, "invalid file type"}
    end
  end

  # Based on what is acceptable in latex engine
  def check_file_naming(filename) do
    filename
    |> Path.rootname()
    |> String.split("-")
    |> case do
      [_font_family, font_style] when font_style in @font_style_name -> true
      _ -> false
    end
  end

  # Define a thumbnail transformation:
  # def transform(:thumb, _) do
  #   {:convert, "-strip -thumbnail 250x250^ -gravity center -extent 250x250 -format png", :png}
  # end

  # def filename(version, _) do
  #   version
  # end

  # Override the storage directory:
  def storage_dir(_version, {_file, scope}) do
    "uploads/assets/#{scope.id}"
  end

  # Provide a default URL if there hasn't been a file uploaded
  def default_url(_version, _scope), do: Minio.generate_url("uploads/images/avatar.png")

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: MIME.from_path(file.file_name)]
  # end
end
