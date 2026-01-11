defmodule GrandTour.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true

    timestamps(type: :utc_datetime)
  end

  # Reserved usernames that conflict with routes or are commonly reserved
  @reserved_usernames ~w(
    about abuse account accounts admin administrator administrators
    api app apps auth authentication authorize
    billing blog bots business
    cache callback cdn cgi client clients code config contact
    copyright create css
    dashboard data delete demo design dev developer developers docs
    documentation download downloads
    edit email emails embed error errors events example
    faq favicon feed feedback file files fonts forum forums
    get github google graphql guest guests guide
    help home host hosting html http https
    image images img info internal invite ios iphone
    javascript jobs js json julian julian-lindner jlxq0
    legal lib library linux login logout logs
    mail mailbox mailer map maps marketing me media member members
    message messages messenger mobile
    new news newsletter nil notifications null
    oauth offline official onboarding open openapi
    page pages partner partners password passwords pay payment
    ping pixel plans plugin plugins policies policy popular post posts
    pricing privacy private product products profile profiles
    public python
    raw readme recent redirect register registration remove
    replies reply report request requests reset resources review
    root rss rules
    sale sales sample save script scripts search security
    server servers service services session sessions settings setup
    share shop signin signout signup site sitemap sites
    smtp source spam ssl sso staging start static stats status
    store style styles subdomain submit subscribe success
    superuser support survey sync system systems
    tag tags team teams template templates terms test testing tests
    theme themes timeline token tokens tools tos tour tours
    trending trip trips trust tutorial tutorials
    undefined unsubscribe update updates upgrade upload uploads
    user username users
    video videos
    web webhook webhooks webmaster website websites widget widgets wiki
    wordpress
    xml xss
    yaml you your
    zero
  )

  @doc """
  A user changeset for registering or changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, GrandTour.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for setting or changing the username.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the username, useful when displaying live validations.
      Defaults to `true`.
  """
  def username_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:username])
    |> validate_username(opts)
  end

  defp validate_username(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:username])
      |> validate_length(:username, min: 3, max: 16)
      |> validate_format(:username, ~r/^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]{1,2}$/,
        message: "must be lowercase letters, numbers, and hyphens only"
      )
      |> validate_format(:username, ~r/^(?!.*--)/, message: "cannot contain consecutive hyphens")
      |> validate_not_reserved()

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:username, GrandTour.Repo)
      |> unique_constraint(:username)
    else
      changeset
    end
  end

  defp validate_not_reserved(changeset) do
    username = get_field(changeset, :username)

    if username && String.downcase(username) in @reserved_usernames do
      add_error(changeset, :username, "is reserved")
    else
      changeset
    end
  end

  @doc """
  Returns the list of reserved usernames.
  """
  def reserved_usernames, do: @reserved_usernames

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%GrandTour.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
