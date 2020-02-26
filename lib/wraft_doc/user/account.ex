defmodule WraftDoc.Account do
  @moduledoc """
  Module that handles the repo connections of the user context.
  """
  # import Ecto.Query, warn: false
  import Ecto
  alias WraftDoc.{Repo, Account.User, Account.Role, Account.Profile}

  @doc """
    User Registration
  """
  @spec registration(map) :: %User{} | Ecto.Changeset.t()
  def registration(params \\ %{}) do
    get_role()
    |> build_assoc(:users)
    |> User.changeset(params)
    |> Repo.insert()
    |> case do
      changeset = {:error, _} ->
        changeset

      {:ok, %User{} = user} ->
        create_profile(user, params)
        user |> Repo.preload(:profile)
    end
  end

  @doc """
    Create profile for the user
  """
  @spec create_profile(%User{}, map) :: {atom, %Profile{}}
  def create_profile(user, params) do
    user
    |> build_assoc(:profile)
    |> Profile.changeset(params)
    |> Repo.insert()
  end

  @doc """
    Find the user with the given email
  """
  def find(email) do
    get_user_by_email(email)
    |> case do
      user = %User{} ->
        user

      _ ->
        {:error, :invalid}
    end
  end

  # Authenticate user and generate token
  def authenticate(%{user: user, password: password}) do
    case password do
      "" ->
        {:error, :no_data}

      _ ->
        case Bcrypt.verify_pass(password, user.encrypted_password) do
          true ->
            WraftDocWeb.Guardian.encode_and_sign(user)

          _ ->
            {:error, :invalid}
        end
    end
  end

  def update_profile(conn, params) do
    current_user = conn.assigns.current_user.id

    user =
      Profile
      |> Repo.get_by(user_id: current_user)
      |> Profile.changeset(params)

    case Repo.update(user) do
      changeset = {:error, _} ->
        changeset

      {:ok, profile_struct} ->
        Repo.preload(profile_struct, :user)
        |> Repo.preload(:country)
    end
  end

  defp get_role(role \\ "user")

  defp get_role(role) when is_binary(role) do
    Repo.get_by(Role, name: role)
  end

  defp get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  defp get_user_by_email(_email) do
    nil
  end
end
