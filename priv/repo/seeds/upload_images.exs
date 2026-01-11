# Script to upload dataset images to R2
#
# Usage:
#   mix run priv/repo/seeds/upload_images.exs
#   mix run priv/repo/seeds/upload_images.exs --dry-run
#   mix run priv/repo/seeds/upload_images.exs --type pois

defmodule ImageUploader do
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [dry_run: :boolean, type: :string])
    dry_run = Keyword.get(opts, :dry_run, false)
    type_filter = Keyword.get(opts, :type)

    types = ["pois", "ferries", "scenic-routes", "shipping"]
    types_to_process = if type_filter, do: [type_filter], else: types

    results =
      Enum.reduce(types_to_process, %{uploaded: 0, skipped: 0, failed: 0}, fn type, acc ->
        IO.puts("\n=== Processing #{type} ===")
        result = process_type(type, dry_run)
        %{
          uploaded: acc.uploaded + result.uploaded,
          skipped: acc.skipped + result.skipped,
          failed: acc.failed + result.failed
        }
      end)

    IO.puts("\n=== Summary ===")
    IO.puts("Uploaded: #{results.uploaded}")
    IO.puts("Skipped: #{results.skipped}")
    IO.puts("Failed: #{results.failed}")

    if dry_run do
      IO.puts("\n(Dry run - no files were actually uploaded)")
    end
  end

  defp process_type("pois", dry_run) do
    base_path = "_old/data/pois/images"
    files = Path.wildcard("#{base_path}/**/*.webp")
    IO.puts("Found #{length(files)} POI images")
    process_files(files, base_path, "datasets/pois", dry_run)
  end

  defp process_type("ferries", dry_run) do
    base_path = "_old/data/ferries/images"
    files = Path.wildcard("#{base_path}/*.webp")
    IO.puts("Found #{length(files)} ferry images")
    process_files(files, base_path, "datasets/ferries", dry_run)
  end

  defp process_type("scenic-routes", dry_run) do
    base_path = "_old/data/scenic-routes/images"
    files = Path.wildcard("#{base_path}/**/*.webp")
    IO.puts("Found #{length(files)} scenic route images")
    process_files(files, base_path, "datasets/scenic-routes", dry_run)
  end

  defp process_type("shipping", dry_run) do
    base_path = "_old/data/shipping/images"
    files = Path.wildcard("#{base_path}/*.webp")
    IO.puts("Found #{length(files)} shipping images")
    process_files(files, base_path, "datasets/shipping", dry_run)
  end

  defp process_type(type, _dry_run) do
    IO.puts("Unknown type: #{type}")
    %{uploaded: 0, skipped: 0, failed: 0}
  end

  defp process_files(files, base_path, prefix, dry_run) do
    total = length(files)

    files
    |> Enum.with_index(1)
    |> Enum.reduce(%{uploaded: 0, skipped: 0, failed: 0}, fn {file, index}, acc ->
      relative_path = String.replace_prefix(file, base_path <> "/", "")
      r2_key = "#{prefix}/#{relative_path}"

      if dry_run do
        IO.puts("  [#{index}/#{total}] Would upload: #{relative_path} -> #{r2_key}")
        %{acc | uploaded: acc.uploaded + 1}
      else
        case upload_file(file, r2_key) do
          {:ok, _url} ->
            if rem(index, 50) == 0 or index == total do
              IO.puts("  [#{index}/#{total}] Uploaded: #{relative_path}")
            end
            %{acc | uploaded: acc.uploaded + 1}

          {:error, reason} ->
            IO.puts("  [#{index}/#{total}] FAILED: #{relative_path} - #{inspect(reason)}")
            %{acc | failed: acc.failed + 1}
        end
      end
    end)
  end

  defp upload_file(local_path, r2_key) do
    case File.read(local_path) do
      {:ok, binary} ->
        content_type = content_type_for(local_path)
        GrandTour.Media.upload_object(r2_key, binary, content_type: content_type)

      {:error, reason} ->
        {:error, {:file_read_error, reason}}
    end
  end

  defp content_type_for(path) do
    case Path.extname(path) |> String.downcase() do
      ".webp" -> "image/webp"
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      _ -> "application/octet-stream"
    end
  end
end

ImageUploader.run(System.argv())
