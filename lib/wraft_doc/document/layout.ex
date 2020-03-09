defmodule WraftDoc.Document.Layout do
  @moduledoc """
  The layout model.
  """
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.Changeset
  alias WraftDoc.Document.Layout

  schema "layout" do
    field(:uuid, Ecto.UUID, autogenerate: true, null: false)
    field(:name, :string, null: false)
    field(:description, :string)
    field(:width, :float)
    field(:height, :float)
    field(:unit, :string)
    field(:slug, :string)
    field(:slug_file, WraftDocWeb.LayoutSlugUploader.Type)
    belongs_to(:engine, WraftDoc.Document.Engine)
    belongs_to(:creator, WraftDoc.Account.User)
    belongs_to(:organisation, WraftDoc.Enterprise.Organisation)

    has_many(:content_types, WraftDoc.Document.ContentType)
    timestamps()
  end

  def changeset(%Layout{} = layout, attrs \\ %{}) do
    layout
    |> cast(attrs, [
      :name,
      :description,
      :width,
      :height,
      :unit,
      :slug,
      :organisation_id
    ])
    |> validate_required([
      :name,
      :description,
      :width,
      :height,
      :unit,
      :slug,
      :organisation_id
    ])
    |> unique_constraint(:name,
      message: "Layout with the same name exists. Use another name.!",
      name: :layout_name_unique_index
    )
  end

  def update_changeset(%Layout{} = layout, attrs \\ %{}) do
    layout
    |> cast(attrs, [
      :name,
      :description,
      :width,
      :height,
      :unit,
      :slug,
      :engine_id
    ])
    |> validate_required([
      :name,
      :description,
      :width,
      :height,
      :unit,
      :slug,
      :engine_id
    ])
    |> unique_constraint(:name,
      message: "Layout with the same name exists. Use another name.!",
      name: :layout_name_unique_index
    )
  end

  def file_changeset(%Layout{} = layout, attrs \\ %{}) do
    layout
    |> cast_attachments(attrs, [:slug_file])
    |> validate_required([:slug_file],
      message: "Cant be blank. Try editing the layout the layout and upload the file again.!"
    )
  end
end
