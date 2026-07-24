defmodule WraftDocWeb.SessionController do
  @moduledoc """
  Session controller module handles session for admin
  """
  use WraftDocWeb, :controller

  alias WraftDoc.InternalUsers
  alias WraftDoc.InternalUsers.InternalUser

  def new(conn, _params) do
    changeset = InternalUsers.change_internal_user()
    render(conn, changeset: changeset)
  end

  def create(conn, %{"session" => params}) do
    password = Map.get(params, "password")

    # Prevent timing attacks and user enumeration
    # Empty passwords skip hashing to avoid generic mitigations bypass
    # Non-existent users invoke dummy hashing to simulate verify_pass delay
    user_lookup_result =
      if password in ["", nil] do
        {:error, :no_data}
      else
        case InternalUsers.get_by_email(Map.get(params, "email")) do
          %InternalUser{} = user -> user
          _ ->
            Bcrypt.no_user_verify()
            {:error, :invalid}
        end
      end

    with %InternalUser{} = user <- user_lookup_result,
         true <- Bcrypt.verify_pass(password, user.encrypted_password),
         false <- user.is_deactivated do
      conn
      |> put_session(:admin_id, user.id)
      |> put_flash(:info, "Signed in successfully.")
      |> redirect(to: kaffy_home_path(conn, :index))
    else
      true ->
        conn
        |> put_flash(:info, "Your account has been deactivated, please contact support.")
        |> redirect(to: session_path(conn, :new))

      _ ->
        conn
        |> put_flash(:error, "Please provide the correct login credentials to login.")
        |> redirect(to: session_path(conn, :new))
    end
  end

  @doc """
  Delete a session.
  """
  def delete(conn, _) do
    conn
    |> delete_session(:admin_id)
    |> put_flash(:info, "Signed out successfully.")
    |> redirect(to: session_path(conn, :new))
  end
end
