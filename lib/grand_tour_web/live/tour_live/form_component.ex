defmodule GrandTourWeb.TourLive.FormComponent do
  use GrandTourWeb, :live_component

  alias GrandTour.Tours

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-bold mb-4">{@title}</h2>

      <.form
        for={@form}
        id="tour-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <.input field={@form[:name]} type="text" label="Name" placeholder="My Grand Tour" />
          <.input
            field={@form[:subtitle]}
            type="textarea"
            label="Description"
            placeholder="A brief description of your tour..."
          />
          <.input field={@form[:is_public]} type="checkbox" label="Make this tour public" />
        </div>

        <div class="modal-action">
          <.link patch={@patch} class="btn btn-ghost">Cancel</.link>
          <button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
            Save Tour
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{tour: tour} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Tours.change_tour(tour))
     end)}
  end

  @impl true
  def handle_event("validate", %{"tour" => tour_params}, socket) do
    changeset = Tours.change_tour(socket.assigns.tour, tour_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"tour" => tour_params}, socket) do
    save_tour(socket, socket.assigns.action, tour_params)
  end

  defp save_tour(socket, :edit, tour_params) do
    case Tours.update_tour(socket.assigns.tour, tour_params) do
      {:ok, tour} ->
        notify_parent({:saved, tour})

        {:noreply,
         socket
         |> put_flash(:info, "Tour updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_tour(socket, :new, tour_params) do
    scope = socket.assigns.scope

    case Tours.create_tour(scope, tour_params) do
      {:ok, tour} ->
        notify_parent({:saved, tour})

        {:noreply,
         socket
         |> put_flash(:info, "Tour created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
