defmodule GrandTourWeb.TourLive.FormComponent do
  use GrandTourWeb, :live_component

  alias GrandTour.Tours
  alias GrandTour.Media

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

          <%!-- Cover Image --%>
          <div>
            <label class="label">
              <span class="label-text">Cover Image</span>
            </label>

            <%!-- Hidden file input - MUST always be rendered for upload system to work --%>
            <.live_file_input upload={@uploads.cover_image} class="hidden" />

            <%= cond do %>
              <% upload_preview(@uploads.cover_image) -> %>
                <%!-- New upload preview --%>
                <div class="relative inline-block w-full max-w-md">
                  <.live_img_preview
                    entry={hd(@uploads.cover_image.entries)}
                    class="w-full h-48 object-cover rounded-lg"
                  />
                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={hd(@uploads.cover_image.entries).ref}
                    phx-target={@myself}
                    class="absolute top-2 right-2 btn btn-circle btn-sm btn-error"
                  >
                    <.icon name="hero-x-mark" class="w-4 h-4" />
                  </button>
                  <%!-- Progress bar overlay --%>
                  <div
                    :for={entry <- @uploads.cover_image.entries}
                    :if={entry.progress > 0 && entry.progress < 100}
                    class="absolute bottom-0 left-0 right-0 bg-black/50 p-2 rounded-b-lg"
                  >
                    <progress
                      class="progress progress-primary w-full"
                      value={entry.progress}
                      max="100"
                    />
                  </div>
                </div>
                <%= for entry <- @uploads.cover_image.entries do %>
                  <p
                    :for={err <- upload_errors(@uploads.cover_image, entry)}
                    class="text-error text-sm mt-2"
                  >
                    {upload_error_to_string(err)}
                  </p>
                <% end %>
              <% @tour.cover_image && !@remove_cover -> %>
                <%!-- Existing cover image --%>
                <div class="relative inline-block w-full max-w-md">
                  <img
                    src={@tour.cover_image}
                    alt="Cover image"
                    class="w-full h-48 object-cover rounded-lg"
                  />
                  <button
                    type="button"
                    phx-click="remove-cover"
                    phx-target={@myself}
                    class="absolute top-2 right-2 btn btn-circle btn-sm btn-error"
                  >
                    <.icon name="hero-x-mark" class="w-4 h-4" />
                  </button>
                </div>
              <% true -> %>
                <%!-- Upload zone (no image) --%>
                <div
                  class="w-full max-w-md h-48 border-2 border-dashed border-base-300 rounded-lg flex flex-col items-center justify-center hover:border-primary transition-colors cursor-pointer"
                  phx-drop-target={@uploads.cover_image.ref}
                >
                  <label for={@uploads.cover_image.ref} class="cursor-pointer text-center">
                    <.icon name="hero-photo" class="w-10 h-10 mx-auto text-base-content/30 mb-2" />
                    <p class="text-sm text-base-content/60">
                      Drag & drop or <span class="text-primary font-medium">browse</span>
                    </p>
                    <p class="text-xs text-base-content/40 mt-1">PNG, JPG, WebP up to 10MB</p>
                  </label>
                </div>
            <% end %>
          </div>

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
    # Only configure upload once on initial mount
    socket =
      if socket.assigns[:uploads] do
        socket
      else
        socket
        |> assign(:uploaded_cover_url, nil)
        |> assign_new(:remove_cover, fn -> false end)
        |> allow_upload(:cover_image,
          accept: ~w(.jpg .jpeg .png .webp),
          max_entries: 1,
          max_file_size: 10_000_000,
          external: &presign_upload/2
        )
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Tours.change_tour(tour))
     end)}
  end

  # Presign upload for R2
  defp presign_upload(entry, socket) do
    tour = socket.assigns.tour
    prefix = if tour.id, do: "tours/#{tour.id}/cover", else: "tours/new/cover"

    {:ok, result} =
      Media.presigned_upload(entry.client_name,
        prefix: prefix,
        content_type: entry.client_type
      )

    meta = %{
      uploader: "R2",
      key: result.key,
      url: result.upload_url,
      public_url: result.public_url
    }

    {:ok, meta, socket}
  end

  defp upload_preview(upload_config) do
    upload_config.entries != []
  end

  defp upload_error_to_string(:too_large), do: "File is too large (max 10MB)"
  defp upload_error_to_string(:not_accepted), do: "Invalid file type"
  defp upload_error_to_string(:too_many_files), do: "Too many files"
  defp upload_error_to_string(err), do: "Upload error: #{inspect(err)}"

  @impl true
  def handle_event("validate", %{"tour" => tour_params}, socket) do
    changeset = Tours.change_tour(socket.assigns.tour, tour_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"tour" => tour_params}, socket) do
    # Check if any uploads are still in progress
    entries_in_progress =
      Enum.any?(socket.assigns.uploads.cover_image.entries, fn entry ->
        entry.progress < 100
      end)

    if entries_in_progress do
      # Don't allow saving while upload is in progress
      {:noreply, socket}
    else
      do_save(socket, tour_params)
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :cover_image, ref)}
  end

  def handle_event("remove-cover", _, socket) do
    # Cancel any in-progress uploads when removing cover
    socket =
      Enum.reduce(socket.assigns.uploads.cover_image.entries, socket, fn entry, acc ->
        cancel_upload(acc, :cover_image, entry.ref)
      end)

    {:noreply, assign(socket, :remove_cover, true)}
  end

  defp do_save(socket, tour_params) do
    # Get uploaded cover image URL if any
    uploaded_urls =
      consume_uploaded_entries(socket, :cover_image, fn %{uploader: "R2"} = meta, _entry ->
        {:ok, meta.public_url}
      end)

    # Determine cover_image value
    tour_params =
      cond do
        # New upload takes precedence
        uploaded_urls != [] ->
          Map.put(tour_params, "cover_image", hd(uploaded_urls))

        # User wants to remove cover
        socket.assigns.remove_cover ->
          Map.put(tour_params, "cover_image", nil)

        # Keep existing
        true ->
          tour_params
      end

    save_tour(socket, socket.assigns.action, tour_params)
  end

  defp save_tour(socket, :edit, tour_params) do
    old_cover = socket.assigns.tour.cover_image

    case Tours.update_tour(socket.assigns.tour, tour_params) do
      {:ok, tour} ->
        # Enqueue image processing if cover_image changed
        if tour.cover_image && tour.cover_image != old_cover do
          Tours.enqueue_cover_image_processing(tour)
        end

        notify_parent({:updated, tour})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_tour(socket, :new, tour_params) do
    scope = socket.assigns.scope

    case Tours.create_tour(scope, tour_params) do
      {:ok, tour} ->
        # Enqueue image processing if cover_image was uploaded
        if tour.cover_image do
          Tours.enqueue_cover_image_processing(tour)
        end

        notify_parent({:created, tour})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
