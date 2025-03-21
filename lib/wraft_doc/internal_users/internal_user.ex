defmodule WraftDoc.InternalUsers.InternalUser do
  @moduledoc """
  Schema for internal users.
  """
  use WraftDoc.Schema

  schema "internal_user" do
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:encrypted_password, :string)
    field(:is_deactivated, :boolean, default: false)

    timestamps()
  end

  def changeset(internal_user, attrs \\ %{}) do
    internal_user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "has invalid format")
    |> validate_length(:password, min: 8, max: 22)
    |> unique_constraint(:email, message: "Email already taken.! Try another email.")
    |> generate_encrypted_password
  end

  def update_changeset(internal_user, attrs \\ %{}) do
    internal_user
    |> cast(attrs, [:email, :password, :is_deactivated])
    |> validate_required([:email, :password, :is_deactivated])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "has invalid format")
    |> unique_constraint(:email, message: "Email already taken.! Try another email.")
    |> generate_encrypted_password
  end
end
