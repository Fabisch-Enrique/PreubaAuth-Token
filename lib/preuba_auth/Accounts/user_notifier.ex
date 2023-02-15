defmodule PreubaAuth.Accounts.UserNotifier do
  import Swoosh.Email

  alias PreubaAuth.Mailer


  #THIS FUNCTION DELIVERS THE EMAIL USING THE APPLICATION MAILER

  defp deliver(receipient, subject, body) do
    email =
      new()
      |> to(receipient)
      |> from({"PreubaAuth", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  THIS FUNCTION DELIVERS INSTRUCTIONS TO CONFIRM ACCOUNT
  """

  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm our account by visiting the URL below

    #{url}

    If you did not create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  THIS FUNCTION DELIVERS INSTRUCTIONS TO RESET YOUR PASSWORD
  """

  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """

    =============================

    Hi #{user.email},

    You can reset your password  by visiting the URL below

    #{url}

    If you did not request this change, plezase ignore this.

    ============================
    """)
  end

  @doc """
  THIS FUNCTION DELIVERS NSTRUCTIONS TO UPDATE USER EMAIL
  """

  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ===========================

    Hi #{user.email},

    You can change your email by visiting the URL below

    #{url}

    If you did not request this change, please ignore this
    """)
  end
end
