defmodule PreubaAuth.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hasshed_password, :string, redact: true
    field :confirmed_at, :naive_datetime

    timestamps()
  end

  @doc """
  USER CHANGESET FOR REGISTRATION

  IT IS IMPORTANT TO VALIDATE THE PASSWORD AND EMAIL LENGTH, ELSE THE DATABASE MAY TRUNCATE THE EMAIL WITHOUT WARNINGS, WHICH MAY LEAD TO UNPREDICTABLE/INSECURE BEHAVIOUR
  """

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email()
    |> validate_password(opts)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and with mno spaces")
    |> validate_length(:email, min: 20, max: 70)
    |> unsafe_validate_unique(:email, PreubaAuth.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 50)
    |> hash_password(opts)
  end

  defp hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts,  :hash_password, true)
    password = get_chamnge(changeset, :password)


    if hash_password? && password && changeset.valid? do
      changeset

      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypyt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A CHANGESET FOR CHANGING THE USER EMAIL
  """

  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A CHANGESET FOR CHANGING THE USER PASSWORD
  """

  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  CONFIRMS THE ACCOUNT BY SETTTING "CONFIRMED_AT"
  """

  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  VERIFIES THE PASSWORD

  IF THERE'S NO USER R THE USER DOESN'T HAVE A PASSWORD, WE CALL "Bcrypt.no_user_verify/0" to avoid timing attacks
  """

  def valid_password?(PreubaAuth.Accounts.User{hashed_password: hashed_password}, password)
    when is_binary(hashed_password) and byte_size(password) > 0 do
      Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  VALIDATES THE CURRENT PASSWORD OTHERWISE ADDS AN ERROR TO THE CHANGESET
  """

  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
