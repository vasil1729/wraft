defmodule WraftDocWeb.Mailer.Email do
  @moduledoc false

  import Swoosh.Email
  alias Swoosh.Attachment
  alias WraftDocWeb.MJML

  def invite_email(org_name, user_name, email, token) do
    join_url = build_join_url(org_name, email, token)

    body = %{
      email: email,
      user_name: user_name,
      org_name: org_name,
      join_url: join_url
    }

    new()
    |> to(email)
    |> from({"Wraft", sender_email()})
    |> subject("Invitation to join #{org_name} in Wraft")
    |> html_body(MJML.Invite.render(body))
  end

  def notification_email(user_name, notification_message, email) do
    new()
    |> to(email)
    |> from({"Wraft", sender_email()})
    |> subject(" #{user_name} ")
    |> html_body("Hi, #{user_name} #{notification_message}")
  end

  @doc """
  Password set link.
  """
  def password_set(name, token, email) do
    redirect_url = build_signup_pass_url(token)

    body = %{
      email: email,
      name: name,
      redirect_url: redirect_url
    }

    new()
    |> to(email)
    |> from({"Wraft", sender_email()})
    |> subject("Welcome to Wraft - Set Your Password")
    |> html_body(MJML.PasswordSet.render(body))
  end

  @doc """
  Password reset link.
  """
  def password_reset(name, token, email) do
    redirect_url = build_reset_password_url(token)

    body = %{
      name: name,
      redirect_url: redirect_url
    }

    new()
    |> to(email)
    |> from({"Wraft", sender_email()})
    |> subject("Forgot your WraftDoc Password?")
    |> html_body(MJML.PasswordReset.render(body))
  end

  @doc """
    User account verification
  """
  def email_verification(email, token) do
    redirect_url = build_email_verification_url(token)
    body = %{redirect_url: redirect_url}

    new()
    |> to(email)
    |> from({"Wraft", sender_email()})
    |> subject("Wraft - Verify your email")
    |> html_body(MJML.EmailVerification.render(body))
  end

  @doc """
    Waiting list approved
  """
  def waiting_list_approved(email, name, token) do
    registration_url = build_registration_url(token)
    body = %{name: name, registration_url: registration_url}

    new()
    |> to(email)
    |> from({"Wraft", sender_email()})
    |> subject("Welcome to Wraft!")
    |> html_body(MJML.Join.render(body))
  end

  @doc """
    Waiting list join
  """
  def waiting_list_join(email, name) do
    body = %{name: name}

    new()
    |> to(email)
    |> from({"Wraft", sender_email()})
    |> subject("Thanks for showing interest in Wraft!")
    |> html_body(MJML.WaitingListJoin.render(body))
  end

  @doc """
    Organisation Delete Code
  """
  def organisation_delete_code(email, delete_code, user_name, organisation_name) do
    body = %{
      delete_code: delete_code,
      user_name: user_name,
      organisation_name: organisation_name
    }

    new()
    |> to(email)
    |> from({"Wraft", sender_email()})
    |> subject("Wraft - Delete Organisation")
    |> html_body(MJML.OrganisationDeleteCode.render(body))
  end

  @doc """
    Document Instance Mail
  """
  def document_instance_share(email, token, instance_id, document_id) do
    document_access_url = build_document_instance_url(token, document_id)
    body = %{document_access_url: document_access_url, instance_id: instance_id}

    new()
    |> to(email)
    |> from({"Wraft", sender_email()})
    |> subject("Wraft - Document Share")
    |> html_body(MJML.DocumentInstanceShare.render(body))
  end

  @doc """
    Document Instance Mail
  """
  def document_instance_mail(
        email,
        subject,
        message,
        cc_list,
        document_pdf_binary,
        instance_file_name
      ) do
    new()
    |> to(email)
    |> maybe_add_cc(cc_list)
    |> from({"Wraft", sender_email()})
    |> subject(subject)
    |> html_body(message)
    |> add_attachment(document_pdf_binary, instance_file_name)
  end

  defp maybe_add_cc(email, nil), do: email

  defp add_attachment(email, document_pdf_binary, instance_file_name) do
    attachment(
      email,
      Attachment.new(
        {:data, document_pdf_binary},
        filename: instance_file_name,
        content_type: "application/pdf",
        type: :inline
      )
    )
  end

  defp sender_email do
    Application.get_env(:wraft_doc, :sender_email)
  end

  defp frontend_url do
    System.get_env("FRONTEND_URL")
  end

  defp build_registration_url(token) do
    URI.encode("#{frontend_url()}/users/login/set_password?token=#{token}")
  end

  defp build_signup_pass_url(token) do
    URI.encode("#{frontend_url()}/users/signup/set-password?token=#{token}")
  end

  defp build_reset_password_url(token) do
    URI.encode("#{frontend_url()}/users/password/reset?token=#{token}")
  end

  defp build_email_verification_url(token) do
    URI.encode("#{frontend_url()}/users/join_invite/verify_email/#{token}}")
  end

  defp build_document_instance_url(token, document_id) do
    URI.encode("#{frontend_url()}/documents/#{document_id}?type=invite&token=#{token}")
  end

  defp build_join_url(org_name, email, token) do
    URI.encode(
      "#{frontend_url()}/users/join_invite?token=#{token}&organisation=#{org_name}&email=#{email}"
    )
  end
end
