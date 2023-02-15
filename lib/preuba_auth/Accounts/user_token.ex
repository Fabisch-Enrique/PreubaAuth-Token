defmodule PreubaAuth.Accounts.UserToken do
  use Ecto.Schema

  import Ecto.Query

  alias PreubaAuth.Accounts.UserToken

  @hash_algorithm :sha256
  @rand_size 32
  @reset_password_validity_in_days 1
  @confirm_validity_in_days 7
  @change_email_validity_in_days 7
  @session_validity_in_days 60

  # IT IS IMPORTANT TO KEEP THE RESET PASSWORD TOKEN EXPIRY SHORT
  # SINCE SOMEONE WITH ACCES CAN TAKE OVER THE ACCOUNT

  schema "user_tokens" do
    field(:token, :binary)
    field(:context, :string)
    field(:sent_to, :string)
    belongs_to(:user, PreubaAuth.Accounts.User)

    timestamps(inserted_at: false)
  end

  @doc """
  GENERATES A TOKEN THAT WILL BE STORED IN A SIGNED PLACE e.g session/cookie

  THE REASON WHY WE STORE SESSION TOKENS IN THE DATABASE,
  EVEN THOUGH PHOENIX PROVIDES A SESSION COOKIE IS BECAUSE PHOENIX DEFAULT SESSION COOKIES ARE NOT PERSISTED
  (they are simply signed and potentially encrypted) THIS  MEANS THEY ARE VALID INDEFINITELY, UNLESS YOU CHANGE THE SIGNING/ENCRYPTION SALT
  """

  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %UserToken{token: token, contex: "session", user_id: user_id}}
  end

  @doc """
  CHECKS IF THE TOKEN IS VALID AND RETURNS ITS UNDERLYING LOOKUP QUERY

  THE QUERY RETURNS THE USER FOUND BY THE TOKEN, IF THERE'S ANY

  THE TOKEN IS VALID IF IT MATCHES THE VALUE IN THE DATABASE AND IT HAS NOT EXPIRED (after @session_validity_in_days)
  """

  def verify_session_token_query(token) do
    query =
      from(token in token_and_context_query(token, "session"),
        join: user in assoc(oken, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: user
      )

    {:ok, query}
  end

  @doc """
  BUILD A TOKENND ITS HASH TO BE DELIVERED TO THE USER'S EMAIL

  THE NON-HASHED TOKEN IS SENT TO THE USER EMAIL WHILE THE HASHED PART IS STORED IN THE DATABASE.
  THE ORIGINAL TOKEN CANNOT BE RECONSTRUCTED, WHICH MEANS ANY ONE WITH READ-ONLY ACCESS TO THE DATABASE CANNOT DIRECTLY USE THE TOKEN IN THE
  APPLICATION TO GAIN ACCESS. MORESO, ID THE USER CHANGES THEIR EMAIL IN THE SYSTEM, THE TOKENS SENT TO PREVIOUS EMAIL ARE NO LONGER VALID.

  THE CODE BELOW IS VERSATILE, OTHER TYPES OF DELIVERY METHODS ARE POSSIBLE e.g phone numbers
  """

  def build_email_token(user, context) do
    build_hash_token(user, context, user.email)
  end

  defp build_hash_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %UserToken{token: hashed_token, context: context, sent_to: sent_to, user_id: user_id}}
  end

  @doc """
  CHECKING IF THE TOKEN S VALID AND RETURNS ITS UNDERLYING LOOKUP QUERY.

  THE QUERY RETURNS THE USER FOUND BY THE TOKEN, IF THERE'S ANY.

  THE TOKEN IS VALID IF IT MATCHES ITS HASHED COUNTERPART IN THE DATABASE AND THE USER EMAIL HAS NOT CHANGED
  THIS FUNCTION ALSO CHECKS IF THE TOKEN IS BEING USED WITHIN A CERTAIN PERIOD, DEPENDING ON THE CONTEXT
  The default contexts supported by this function are either "confirm", for account confirmation emails, and "reset_password",
  for resetting the password. For verifying requests to change the email,
  see ""verify_change_email_token_query/2"".
  """

  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded)
        days = days_for_context(context)

        query =
          from(token in token_and_context_query(hashed_token, context),
            join: user in assoc(token, user),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == user.email,
            select: user
          )

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  @doc """
  CHECKS IF THE TOKEN IS VALID AND RETURNS ITS UNDERLYING LOOKUP QUERY.

  THE QUERY RETURNS THE USER FOUND BY THE TOKEN, IF THERE'S ANY.

  THIS IS USED TO VALIDATE REQUESTS TO CHANGE THE USER EMAIL. IT IS DIFFERENT FROM "verify_email_token_query/2" PRECISELY BECAUSE,
  "verify_email_token_query/2" validates that the email has not changed, which is the starting point of this function.

  THE GIVEN TOKEN IS VALID IF IT MATCHES ITS HASHED COUNTERPART IN THE DATABASE AND IF IT HAS  NOT EXPIRED (after @change_email_validity_in_days)
  THE CONTEXT MUST ALWAYS START WITH change:
  """

  def verify_change_email_token_query(token, "change:" <> _ = context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from(token in token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@change_email_validity_in_days, "day")
          )

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  RETUNS THE TOKEN STRUCT OR THE GIVEN TOKEN VALUE AND CONTEXT
  """

  def user_and_context_query(user, :all) do
    from t in UserToken, where: t.user_id == ^user.id
  end

  def user_and_context_query(user, [_ | _] = context) do
    from t in UserToken, where: t.user_id == ^user.id andt.context in ^contexts
  end
end
