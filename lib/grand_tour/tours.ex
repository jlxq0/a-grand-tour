defmodule GrandTour.Tours do
  @moduledoc """
  The Tours context.
  """

  import Ecto.Query, warn: false
  alias GrandTour.Repo
  alias GrandTour.Accounts.Scope
  alias GrandTour.Tours.Tour
  alias GrandTour.Tours.Trip
  alias GrandTour.Workers.ImageProcessor

  @doc """
  Returns the list of tours for the current user.

  ## Examples

      iex> list_tours(scope)
      [%Tour{}, ...]

  """
  def list_tours(%Scope{user: user}) do
    Repo.all(from t in Tour, where: t.user_id == ^user.id, order_by: [desc: t.updated_at])
  end

  @doc """
  Returns the list of public tours (for any user).

  ## Examples

      iex> list_public_tours()
      [%Tour{}, ...]

  """
  def list_public_tours do
    Repo.all(from t in Tour, where: t.is_public == true, order_by: [desc: t.updated_at])
  end

  @doc """
  Gets a single tour for the current user.

  Raises `Ecto.NoResultsError` if the Tour does not exist or doesn't belong to the user.

  ## Examples

      iex> get_tour!(scope, 123)
      %Tour{}

      iex> get_tour!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_tour!(%Scope{user: user}, id) do
    Repo.one!(from t in Tour, where: t.id == ^id and t.user_id == ^user.id)
  end

  @doc """
  Gets a single tour for the current user, returns nil if not found.

  ## Examples

      iex> get_tour(scope, 123)
      %Tour{}

      iex> get_tour(scope, 456)
      nil

  """
  def get_tour(%Scope{user: user}, id) do
    Repo.one(from t in Tour, where: t.id == ^id and t.user_id == ^user.id)
  end

  @doc """
  Gets a single tour by user and slug.

  Raises `Ecto.NoResultsError` if the Tour does not exist.

  ## Examples

      iex> get_tour_by_slug!(user, "my-tour")
      %Tour{}

      iex> get_tour_by_slug!(user, "unknown")
      ** (Ecto.NoResultsError)

  """
  def get_tour_by_slug!(user, slug) when is_binary(slug) do
    Repo.one!(from t in Tour, where: t.user_id == ^user.id and t.slug == ^slug)
  end

  @doc """
  Gets a single tour by user and slug, returns nil if not found.

  ## Examples

      iex> get_tour_by_slug(user, "my-tour")
      %Tour{}

      iex> get_tour_by_slug(user, "unknown")
      nil

  """
  def get_tour_by_slug(user, slug) when is_binary(slug) do
    Repo.one(from t in Tour, where: t.user_id == ^user.id and t.slug == ^slug)
  end

  @doc """
  Creates a tour for the current user.

  ## Examples

      iex> create_tour(scope, %{field: value})
      {:ok, %Tour{}}

      iex> create_tour(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tour(%Scope{user: user}, attrs \\ %{}) do
    %Tour{user_id: user.id}
    |> Tour.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tour.

  ## Examples

      iex> update_tour(tour, %{field: new_value})
      {:ok, %Tour{}}

      iex> update_tour(tour, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tour(%Tour{} = tour, attrs) do
    tour
    |> Tour.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tour.

  ## Examples

      iex> delete_tour(tour)
      {:ok, %Tour{}}

      iex> delete_tour(tour)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tour(%Tour{} = tour) do
    Repo.delete(tour)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tour changes.

  ## Examples

      iex> change_tour(tour)
      %Ecto.Changeset{data: %Tour{}}

  """
  def change_tour(%Tour{} = tour, attrs \\ %{}) do
    Tour.changeset(tour, attrs)
  end

  @doc """
  Enqueues a background job to process the tour's cover image.

  Creates thumb, medium, and large WebP variants of the original image
  and uploads them to R2. Updates the tour's cover_image_variants field.

  ## Examples

      iex> enqueue_cover_image_processing(tour)
      {:ok, %Oban.Job{}}

  """
  def enqueue_cover_image_processing(%Tour{id: tour_id, cover_image: image_url})
      when is_binary(image_url) and image_url != "" do
    %{tour_id: tour_id, image_url: image_url}
    |> ImageProcessor.new()
    |> Oban.insert()
  end

  def enqueue_cover_image_processing(_tour), do: {:ok, :no_image}

  # Trip functions

  @doc """
  Returns the list of trips for a tour, ordered by position.

  ## Examples

      iex> list_trips(tour)
      [%Trip{}, ...]

  """
  def list_trips(%Tour{} = tour) do
    Repo.all(from t in Trip, where: t.tour_id == ^tour.id, order_by: [asc: t.position])
  end

  @doc """
  Gets a single trip.

  Raises `Ecto.NoResultsError` if the Trip does not exist.

  ## Examples

      iex> get_trip!(123)
      %Trip{}

      iex> get_trip!(456)
      ** (Ecto.NoResultsError)

  """
  def get_trip!(id), do: Repo.get!(Trip, id)

  @doc """
  Gets a single trip, returns nil if not found.

  ## Examples

      iex> get_trip(123)
      %Trip{}

      iex> get_trip(456)
      nil

  """
  def get_trip(id), do: Repo.get(Trip, id)

  @doc """
  Gets a single trip with its tour preloaded.
  """
  def get_trip_with_tour!(id) do
    Repo.get!(Trip, id) |> Repo.preload(:tour)
  end

  @doc """
  Gets a single trip by tour and slug.

  Raises `Ecto.NoResultsError` if the Trip does not exist.

  ## Examples

      iex> get_trip_by_slug!(tour, "europe-summer")
      %Trip{}

      iex> get_trip_by_slug!(tour, "unknown")
      ** (Ecto.NoResultsError)

  """
  def get_trip_by_slug!(%Tour{} = tour, slug) when is_binary(slug) do
    Repo.one!(from t in Trip, where: t.tour_id == ^tour.id and t.slug == ^slug)
  end

  @doc """
  Gets a single trip by tour and slug, returns nil if not found.

  ## Examples

      iex> get_trip_by_slug(tour, "europe-summer")
      %Trip{}

      iex> get_trip_by_slug(tour, "unknown")
      nil

  """
  def get_trip_by_slug(%Tour{} = tour, slug) when is_binary(slug) do
    Repo.one(from t in Trip, where: t.tour_id == ^tour.id and t.slug == ^slug)
  end

  @doc """
  Returns the number of trips in a tour.
  """
  def count_trips(%Tour{} = tour) do
    Repo.one(from t in Trip, where: t.tour_id == ^tour.id, select: count(t.id))
  end

  @doc """
  Creates a trip for a tour.

  ## Examples

      iex> create_trip(tour, %{name: "Trip 1"})
      {:ok, %Trip{}}

      iex> create_trip(tour, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_trip(%Tour{} = tour, attrs \\ %{}) do
    position = next_trip_position(tour)

    %Trip{tour_id: tour.id, position: position}
    |> Trip.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a trip.

  ## Examples

      iex> update_trip(trip, %{name: "Updated"})
      {:ok, %Trip{}}

      iex> update_trip(trip, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_trip(%Trip{} = trip, attrs) do
    trip
    |> Trip.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a trip and reorders remaining trips.

  Returns `{:error, :last_trip}` if this is the only trip in the tour.

  ## Examples

      iex> delete_trip(trip)
      {:ok, %Trip{}}

      iex> delete_trip(last_trip)
      {:error, :last_trip}

  """
  def delete_trip(%Trip{} = trip) do
    trip_count = Repo.one(from t in Trip, where: t.tour_id == ^trip.tour_id, select: count(t.id))

    if trip_count <= 1 do
      {:error, :last_trip}
    else
      Repo.transaction(fn ->
        case Repo.delete(trip) do
          {:ok, deleted_trip} ->
            # Reorder remaining trips to close the gap
            from(t in Trip,
              where: t.tour_id == ^trip.tour_id and t.position > ^trip.position
            )
            |> Repo.update_all(inc: [position: -1])

            deleted_trip

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking trip changes.

  ## Examples

      iex> change_trip(trip)
      %Ecto.Changeset{data: %Trip{}}

  """
  def change_trip(%Trip{} = trip, attrs \\ %{}) do
    Trip.changeset(trip, attrs)
  end

  @doc """
  Reorders trips by updating their positions.
  Takes a list of trip IDs in the desired order.

  ## Examples

      iex> reorder_trips(tour, [trip3_id, trip1_id, trip2_id])
      :ok

  """
  def reorder_trips(%Tour{} = tour, trip_ids) when is_list(trip_ids) do
    Repo.transaction(fn ->
      trip_ids
      |> Enum.with_index(1)
      |> Enum.each(fn {trip_id, position} ->
        from(t in Trip, where: t.id == ^trip_id and t.tour_id == ^tour.id)
        |> Repo.update_all(set: [position: position])
      end)
    end)

    :ok
  end

  @doc """
  Moves a trip to a new position within the tour.
  """
  def move_trip(%Trip{} = trip, new_position) when is_integer(new_position) do
    old_position = trip.position

    cond do
      new_position == old_position ->
        {:ok, trip}

      new_position < old_position ->
        # Moving up: increment positions of trips between new and old
        Repo.transaction(fn ->
          from(t in Trip,
            where:
              t.tour_id == ^trip.tour_id and
                t.position >= ^new_position and
                t.position < ^old_position
          )
          |> Repo.update_all(inc: [position: 1])

          from(t in Trip, where: t.id == ^trip.id)
          |> Repo.update_all(set: [position: new_position])

          Repo.get!(Trip, trip.id)
        end)

      new_position > old_position ->
        # Moving down: decrement positions of trips between old and new
        Repo.transaction(fn ->
          from(t in Trip,
            where:
              t.tour_id == ^trip.tour_id and
                t.position > ^old_position and
                t.position <= ^new_position
          )
          |> Repo.update_all(inc: [position: -1])

          from(t in Trip, where: t.id == ^trip.id)
          |> Repo.update_all(set: [position: new_position])

          Repo.get!(Trip, trip.id)
        end)
    end
  end

  # Private helpers

  defp next_trip_position(%Tour{} = tour) do
    query = from t in Trip, where: t.tour_id == ^tour.id, select: max(t.position)

    case Repo.one(query) do
      nil -> 1
      max_position -> max_position + 1
    end
  end
end
