defmodule GrandTourWeb.TripLive.FormComponent do
  use GrandTourWeb, :live_component

  alias GrandTour.Tours

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-bold mb-4">{@title}</h2>

      <.form
        for={@form}
        id="trip-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <.input field={@form[:name]} type="text" label="Name" placeholder="European Leg" />
          <.input
            field={@form[:subtitle]}
            type="textarea"
            label="Description"
            placeholder="A brief description of this trip..."
          />

          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:start_date]} type="date" label="Start Date" />
            <.input field={@form[:end_date]} type="date" label="End Date" />
          </div>

          <.input
            field={@form[:status]}
            type="select"
            label="Status"
            options={[
              {"Planning", "planning"},
              {"Active", "active"},
              {"Completed", "completed"}
            ]}
          />
        </div>

        <div class="modal-action">
          <.link patch={@patch} class="btn btn-ghost">Cancel</.link>
          <button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
            Save Trip
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{trip: trip} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Tours.change_trip(trip))
     end)}
  end

  @impl true
  def handle_event("validate", %{"trip" => trip_params}, socket) do
    changeset = Tours.change_trip(socket.assigns.trip, trip_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"trip" => trip_params}, socket) do
    save_trip(socket, socket.assigns.action, trip_params)
  end

  defp save_trip(socket, :edit_trip, trip_params) do
    case Tours.update_trip(socket.assigns.trip, trip_params) do
      {:ok, trip} ->
        notify_parent({:updated, trip})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_trip(socket, :new_trip, trip_params) do
    case Tours.create_trip(socket.assigns.tour, trip_params) do
      {:ok, trip} ->
        notify_parent({:created, trip})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
