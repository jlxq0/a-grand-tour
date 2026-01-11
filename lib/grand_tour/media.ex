defmodule GrandTour.Media do
  @moduledoc """
  Context for handling media storage via Cloudflare R2.

  Provides presigned URLs for direct client uploads and downloads to/from R2.
  """

  @doc """
  Generates a presigned URL for uploading a file to R2.

  Returns a map with:
  - `:upload_url` - The presigned URL for PUT request
  - `:key` - The object key in R2
  - `:public_url` - The public URL for accessing the file after upload

  ## Options

  - `:prefix` - Path prefix for the object key (e.g., "tours/123/images")
  - `:content_type` - MIME type of the file (default: "application/octet-stream")
  - `:expires_in` - Expiration time in seconds (default: 3600)
  - `:max_size` - Maximum file size in bytes (optional)

  ## Examples

      iex> presigned_upload("photo.jpg", prefix: "tours/abc/images", content_type: "image/jpeg")
      {:ok, %{
        upload_url: "https://...",
        key: "tours/abc/images/uuid-photo.jpg",
        public_url: "https://media.grandtour.com/tours/abc/images/uuid-photo.jpg"
      }}
  """
  def presigned_upload(filename, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "uploads")
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")
    expires_in = Keyword.get(opts, :expires_in, 3600)

    # Generate unique key with UUID to prevent collisions
    ext = Path.extname(filename)
    base = Path.basename(filename, ext) |> sanitize_filename()
    uuid = generate_uuid()
    key = "#{prefix}/#{uuid}-#{base}#{ext}"

    config = media_config()

    presign_opts = [
      expires_in: expires_in,
      virtual_host: false,
      query_params: [{"Content-Type", content_type}]
    ]

    {:ok, upload_url} =
      :s3
      |> ExAws.Config.new([])
      |> ExAws.S3.presigned_url(:put, config.bucket, key, presign_opts)

    public_url = "#{config.public_url}/#{key}"

    {:ok,
     %{
       upload_url: upload_url,
       key: key,
       public_url: public_url,
       content_type: content_type
     }}
  end

  @doc """
  Generates a presigned URL for downloading a file from R2.

  Returns a presigned URL that allows temporary access to a private object.

  ## Options

  - `:expires_in` - Expiration time in seconds (default: 3600)

  ## Examples

      iex> presigned_download("tours/abc/images/photo.jpg")
      {:ok, "https://..."}
  """
  def presigned_download(key, opts \\ []) do
    expires_in = Keyword.get(opts, :expires_in, 3600)
    config = media_config()

    presign_opts = [
      expires_in: expires_in,
      virtual_host: false
    ]

    :s3
    |> ExAws.Config.new([])
    |> ExAws.S3.presigned_url(:get, config.bucket, key, presign_opts)
  end

  @doc """
  Deletes an object from R2.

  ## Examples

      iex> delete_object("tours/abc/images/photo.jpg")
      :ok
  """
  def delete_object(key) do
    config = media_config()

    case ExAws.S3.delete_object(config.bucket, key) |> ExAws.request() do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deletes multiple objects from R2.

  ## Examples

      iex> delete_objects(["path/to/file1.jpg", "path/to/file2.jpg"])
      :ok
  """
  def delete_objects(keys) when is_list(keys) do
    config = media_config()

    case ExAws.S3.delete_multiple_objects(config.bucket, keys) |> ExAws.request() do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns the public URL for a given object key.

  This is the direct URL without presigning, useful when the bucket
  has a public access policy or CDN configured.
  """
  def public_url(key) do
    config = media_config()
    "#{config.public_url}/#{key}"
  end

  @doc """
  Downloads an object from R2 and returns the binary content.

  ## Examples

      iex> download_object("tours/abc/cover/photo.jpg")
      {:ok, <<binary>>}
  """
  def download_object(key) do
    config = media_config()

    case ExAws.S3.get_object(config.bucket, key) |> ExAws.request() do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Uploads binary content directly to R2.

  ## Options

  - `:content_type` - MIME type (default: "application/octet-stream")

  ## Examples

      iex> upload_object("tours/abc/cover/photo.webp", binary, content_type: "image/webp")
      {:ok, "https://pub-xxx.r2.dev/tours/abc/cover/photo.webp"}
  """
  def upload_object(key, binary, opts \\ []) do
    config = media_config()
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")

    case ExAws.S3.put_object(config.bucket, key, binary, content_type: content_type)
         |> ExAws.request() do
      {:ok, _} -> {:ok, public_url(key)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Extracts the object key from a public URL.

  Returns nil if the URL doesn't match the expected pattern.

  ## Examples

      iex> key_from_url("https://pub-xxx.r2.dev/tours/abc/cover/photo.jpg")
      "tours/abc/cover/photo.jpg"

      iex> key_from_url("https://other.com/photo.jpg")
      nil
  """
  def key_from_url(url) do
    config = media_config()
    base_url = config.public_url

    if String.starts_with?(url, base_url) do
      String.replace_prefix(url, base_url <> "/", "")
    else
      nil
    end
  end

  @doc """
  Lists objects in R2 with the given prefix.

  ## Options

  - `:max_keys` - Maximum number of keys to return (default: 1000)
  - `:continuation_token` - Token for pagination

  ## Examples

      iex> list_objects("tours/abc/images/")
      {:ok, [%{key: "tours/abc/images/photo.jpg", size: 12345, ...}]}
  """
  def list_objects(prefix, opts \\ []) do
    config = media_config()
    max_keys = Keyword.get(opts, :max_keys, 1000)

    request =
      ExAws.S3.list_objects(config.bucket,
        prefix: prefix,
        max_keys: max_keys
      )

    case ExAws.request(request) do
      {:ok, %{body: %{contents: contents}}} ->
        objects =
          Enum.map(contents, fn obj ->
            %{
              key: obj.key,
              size: String.to_integer(obj.size),
              last_modified: obj.last_modified,
              etag: obj.e_tag
            }
          end)

        {:ok, objects}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Configures CORS on the R2 bucket to allow browser uploads.

  If R2_API_TOKEN environment variable is set, uses the Cloudflare API.
  Otherwise, prints instructions for manual configuration via dashboard.
  """
  def configure_cors do
    config = media_config()
    api_token = System.get_env("R2_API_TOKEN")
    # Extract account ID from host config (e.g., "xxx.r2.cloudflarestorage.com")
    host = Application.get_env(:ex_aws, :s3)[:host] || ""
    account_id = host |> String.split(".") |> List.first()

    cors_policy = [
      %{
        "AllowedOrigins" => [
          "http://localhost:4001",
          "https://a-grand-tour.com",
          "https://*.a-grand-tour.com"
        ],
        "AllowedMethods" => ["GET", "PUT", "HEAD"],
        "AllowedHeaders" => ["Content-Type"],
        "ExposeHeaders" => ["ETag"],
        "MaxAgeSeconds" => 3600
      }
    ]

    if is_nil(api_token) or api_token == "" do
      IO.puts("""

      ============================================================
      CORS Configuration Required
      ============================================================

      To enable file uploads from the browser, configure CORS on
      your R2 bucket via the Cloudflare dashboard:

      1. Go to: https://dash.cloudflare.com/?to=/r2/#{config.bucket}/settings
      2. Under "CORS Policy", click "Add CORS policy"
      3. Select the "JSON" tab and paste:

      #{Jason.encode!(cors_policy, pretty: true)}

      4. Click "Save"

      Or set R2_API_TOKEN environment variable and run this again.
      ============================================================
      """)

      {:ok, :instructions_printed}
    else
      url =
        "https://api.cloudflare.com/client/v4/accounts/#{account_id}/r2/buckets/#{config.bucket}/cors"

      case Req.put(url, json: cors_policy, headers: [{"Authorization", "Bearer #{api_token}"}]) do
        {:ok, %{status: status, body: body}} when status in 200..299 ->
          IO.puts("CORS configured successfully for bucket: #{config.bucket}")
          {:ok, body}

        {:ok, %{status: status, body: body}} ->
          IO.puts("Failed to configure CORS (#{status}): #{inspect(body)}")
          {:error, {:http_error, status, body}}

        {:error, reason} ->
          IO.puts("Failed to configure CORS: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  # Private helpers

  defp media_config do
    config = Application.get_env(:grand_tour, :media, [])

    %{
      bucket: Keyword.get(config, :bucket, "grandtour-media-dev"),
      public_url: Keyword.get(config, :public_url, "https://media-dev.grandtour.com")
    }
  end

  defp sanitize_filename(filename) do
    filename
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\-_]/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
    |> String.slice(0, 50)
  end

  defp generate_uuid do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
    |> String.slice(0, 12)
  end
end
