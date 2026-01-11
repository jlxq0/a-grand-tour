defmodule GrandTour.Tours do
  @moduledoc """
  The Tours context.
  """

  import Ecto.Query, warn: false
  alias GrandTour.Repo
  alias GrandTour.Tours.Tour
  alias GrandTour.Tours.Trip

  @doc """
  Returns the list of tours.

  ## Examples

      iex> list_tours()
      [%Tour{}, ...]

  """
  def list_tours do
    Repo.all(from t in Tour, order_by: [desc: t.updated_at])
  end

  @doc """
  Returns the list of public tours.

  ## Examples

      iex> list_public_tours()
      [%Tour{}, ...]

  """
  def list_public_tours do
    Repo.all(from t in Tour, where: t.is_public == true, order_by: [desc: t.updated_at])
  end

  @doc """
  Gets a single tour.

  Raises `Ecto.NoResultsError` if the Tour does not exist.

  ## Examples

      iex> get_tour!(123)
      %Tour{}

      iex> get_tour!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tour!(id), do: Repo.get!(Tour, id)

  @doc """
  Gets a single tour, returns nil if not found.

  ## Examples

      iex> get_tour(123)
      %Tour{}

      iex> get_tour(456)
      nil

  """
  def get_tour(id), do: Repo.get(Tour, id)

  @doc """
  Creates a tour.

  ## Examples

      iex> create_tour(%{field: value})
      {:ok, %Tour{}}

      iex> create_tour(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tour(attrs \\ %{}) do
    %Tour{}
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

  ## Examples

      iex> delete_trip(trip)
      {:ok, %Trip{}}

  """
  def delete_trip(%Trip{} = trip) do
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
