defmodule GrandTour.Workers.ImageProcessor do
  @moduledoc """
  Oban worker for processing uploaded images.

  Generates three variants (thumb, medium, large) in WebP format
  and uploads them to R2.
  """

  use Oban.Worker,
    queue: :media,
    max_attempts: 3,
    unique: [period: 60, fields: [:args, :queue]]

  alias GrandTour.Repo
  alias GrandTour.Media
  alias GrandTour.Tours.Tour

  require Logger

  @variants [
    {:thumb, 200},
    {:medium, 800},
    {:large, 1600}
  ]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"tour_id" => tour_id, "image_url" => image_url}}) do
    Logger.info("[ImageProcessor] Starting processing for tour #{tour_id}")

    tour = Repo.get!(Tour, tour_id)

    # Mark as processing
    update_variants(tour, %{"processing_status" => "pending"})

    with {:ok, key} <- extract_key(image_url),
         {:ok, binary} <- Media.download_object(key),
         {:ok, image} <- Image.from_binary(binary),
         {:ok, original_info} <- get_image_info(image, key, image_url),
         {:ok, variant_results} <- process_variants(image, key) do
      # Build final variants map
      variants = build_variants_map(original_info, variant_results)
      update_variants(tour, variants)

      # Update cover_image to use the large variant
      if large = variants["large"] do
        tour
        |> Ecto.Changeset.change(cover_image: large["url"])
        |> Repo.update()
      end

      Logger.info("[ImageProcessor] Completed processing for tour #{tour_id}")
      :ok
    else
      {:error, reason} ->
        Logger.error("[ImageProcessor] Failed for tour #{tour_id}: #{inspect(reason)}")

        update_variants(tour, %{
          "processing_status" => "failed",
          "error" => inspect(reason)
        })

        {:error, reason}
    end
  end

  defp extract_key(image_url) do
    case Media.key_from_url(image_url) do
      nil -> {:error, :invalid_url}
      key -> {:ok, key}
    end
  end

  defp get_image_info(image, key, url) do
    with {:ok, width} <- Image.width(image),
         {:ok, height} <- Image.height(image) do
      format = key |> Path.extname() |> String.trim_leading(".") |> String.downcase()

      {:ok,
       %{
         "url" => url,
         "key" => key,
         "width" => width,
         "height" => height,
         "format" => format
       }}
    end
  end

  defp process_variants(image, original_key) do
    base_key = original_key |> Path.rootname()

    results =
      @variants
      |> Task.async_stream(
        fn {name, max_width} ->
          process_single_variant(image, base_key, name, max_width)
        end,
        timeout: :timer.minutes(2),
        max_concurrency: 3
      )
      |> Enum.reduce({:ok, %{}}, fn
        {:ok, {:ok, {name, info}}}, {:ok, acc} ->
          {:ok, Map.put(acc, Atom.to_string(name), info)}

        {:ok, {:error, reason}}, _ ->
          {:error, reason}

        {:exit, reason}, _ ->
          {:error, {:task_exit, reason}}
      end)

    results
  end

  defp process_single_variant(image, base_key, name, max_width) do
    variant_key = "#{base_key}-#{name}.webp"

    with {:ok, resized} <- resize_image(image, max_width),
         {:ok, binary} <- Image.write(resized, :memory, suffix: ".webp", quality: 85),
         {:ok, url} <- Media.upload_object(variant_key, binary, content_type: "image/webp") do
      {:ok, width} = Image.width(resized)
      {:ok, height} = Image.height(resized)

      {:ok,
       {name,
        %{
          "url" => url,
          "key" => variant_key,
          "width" => width,
          "height" => height,
          "size" => byte_size(binary),
          "format" => "webp"
        }}}
    end
  end

  defp resize_image(image, max_width) do
    {:ok, current_width} = Image.width(image)

    if current_width <= max_width do
      # Image is already smaller, just return it (will be converted to webp on write)
      {:ok, image}
    else
      Image.thumbnail(image, max_width, crop: :none)
    end
  end

  defp build_variants_map(original_info, variant_results) do
    variant_results
    |> Map.put("original", original_info)
    |> Map.put("processing_status", "completed")
    |> Map.put("processed_at", DateTime.utc_now() |> DateTime.to_iso8601())
    |> Map.put("error", nil)
  end

  defp update_variants(tour, variants) do
    merged = Map.merge(tour.cover_image_variants || %{}, variants)

    tour
    |> Ecto.Changeset.change(cover_image_variants: merged)
    |> Repo.update()
  end
end
