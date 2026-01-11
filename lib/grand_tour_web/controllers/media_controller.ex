defmodule GrandTourWeb.MediaController do
  use GrandTourWeb, :controller

  alias GrandTour.Media

  @doc """
  Returns a presigned URL for uploading a file to R2.

  Expects JSON body:
  - `filename` - Original filename
  - `content_type` - MIME type of the file
  - `prefix` - Path prefix (e.g., "tours/abc-123/images")

  Returns JSON:
  - `upload_url` - Presigned PUT URL
  - `key` - Object key in R2
  - `public_url` - Public URL for the uploaded file
  """
  def presign_upload(conn, params) do
    filename = params["filename"] || "file"
    content_type = params["content_type"] || "application/octet-stream"
    prefix = params["prefix"] || "uploads"

    {:ok, result} =
      Media.presigned_upload(filename,
        prefix: prefix,
        content_type: content_type,
        expires_in: 3600
      )

    json(conn, %{
      upload_url: result.upload_url,
      key: result.key,
      public_url: result.public_url,
      content_type: result.content_type
    })
  end

  @doc """
  Returns a presigned URL for downloading a file from R2.

  Query params:
  - `key` - Object key in R2

  Returns JSON:
  - `download_url` - Presigned GET URL
  """
  def presign_download(conn, %{"key" => key}) do
    case Media.presigned_download(key, expires_in: 3600) do
      {:ok, download_url} ->
        json(conn, %{download_url: download_url})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to generate presigned URL", reason: inspect(reason)})
    end
  end

  def presign_download(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameter: key"})
  end
end
