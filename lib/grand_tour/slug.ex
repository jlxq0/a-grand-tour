defmodule GrandTour.Slug do
  @moduledoc """
  Generates URL-friendly slugs from names.
  """

  @doc """
  Generate a URL-friendly slug from a name.

  ## Examples

      iex> GrandTour.Slug.generate("My Grand Tour 2027!")
      "my-grand-tour-2027"

      iex> GrandTour.Slug.generate("Été en France")
      "t-en-france"

  """
  def generate(name, max_length \\ 64) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
    |> String.slice(0, max_length)
  end

  @doc """
  Append a random suffix to make slug unique.
  Called when a slug collision is detected (unique constraint fails).

  ## Examples

      iex> slug = GrandTour.Slug.with_random_suffix("my-tour")
      iex> String.starts_with?(slug, "my-tour-")
      true

  """
  def with_random_suffix(slug, max_length \\ 64) do
    suffix = random_suffix(4)
    # Leave room for -xxxx (5 chars)
    base = String.slice(slug, 0, max_length - 5)
    "#{base}-#{suffix}"
  end

  defp random_suffix(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.encode32(case: :lower, padding: false)
    |> String.slice(0, length)
  end
end
