defmodule GrandTourWeb.DatasetViews do
  @moduledoc """
  Components for rendering dataset items in different view modes:
  - List view: Compact horizontal rows
  - Table view: Sortable columns
  - Card view: Grid of cards with images
  """
  use Phoenix.Component

  import GrandTourWeb.CoreComponents, only: [icon: 1]
  import GrandTourWeb.SharedComponents, only: [new_item_card: 1]

  # ===========================================================================
  # List View
  # ===========================================================================

  @doc """
  Renders dataset items in a list view (compact rows).

  ## Attributes
    - items: List of dataset items
    - visible_fields: List of field names to show
    - on_click: Event to push when item is clicked
    - media_url_fn: Function to convert image path to full URL
  """
  attr :items, :list, required: true
  attr :visible_fields, :list, default: ["name", "description", "rating"]
  attr :on_click, :string, default: nil
  attr :media_url_fn, :any, default: nil
  attr :id, :string, default: "dataset-list"

  def dataset_list_view(assigns) do
    ~H"""
    <div id={@id} class="space-y-2">
      <div
        :for={item <- @items}
        id={"item-#{item.id}"}
        class="p-3 bg-base-200 rounded-lg hover:bg-base-300 cursor-pointer transition-colors"
        data-filterable
        data-filterable-text={item.name <> " " <> (item.description || "")}
        phx-click={@on_click}
        phx-value-id={item.id}
      >
        <div class="flex items-start gap-3">
          <div :if={has_images?(item) && "images" in @visible_fields} class="flex-shrink-0">
            <img
              src={get_image_url(item, @media_url_fn)}
              alt={item.name}
              class="w-12 h-12 object-cover rounded"
            />
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="font-medium truncate">{item.name}</span>
              <span :if={item.rating && "rating" in @visible_fields} class="text-warning text-sm">
                {render_stars(item.rating)}
              </span>
              <span
                :if={get_property(item, "country_code") && "country_code" in @visible_fields}
                class="text-base-content/60 text-sm"
              >
                {get_property(item, "country_code")}
              </span>
            </div>
            <p
              :if={item.description && "description" in @visible_fields}
              class="text-sm text-base-content/70 line-clamp-2 mt-1"
            >
              {item.description}
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ===========================================================================
  # Table View
  # ===========================================================================

  @doc """
  Renders dataset items in a sortable table view.

  ## Attributes
    - items: List of dataset items
    - visible_fields: List of field names to show as columns
    - sort_field: Current sort field
    - sort_direction: "asc" or "desc"
    - on_sort: Event name for sorting
    - on_click: Event to push when row is clicked
    - media_url_fn: Function to convert image path to full URL
  """
  attr :items, :list, required: true
  attr :visible_fields, :list, default: ["name", "rating"]
  attr :sort_field, :string, default: "name"
  attr :sort_direction, :string, default: "asc"
  attr :on_sort, :string, default: "sort"
  attr :on_click, :string, default: nil
  attr :media_url_fn, :any, default: nil
  attr :id, :string, default: "dataset-table"

  def dataset_table_view(assigns) do
    ~H"""
    <div id={@id} class="overflow-x-auto">
      <table class="table table-zebra w-full">
        <thead>
          <tr>
            <th :if={"images" in @visible_fields} class="w-12"></th>
            <th
              :for={field <- @visible_fields -- ["images"]}
              class="cursor-pointer hover:bg-base-200"
              phx-click={@on_sort}
              phx-value-field={field}
            >
              <div class="flex items-center gap-1">
                {field_label(field)}
                <span :if={@sort_field == field} class="text-primary">
                  <.icon
                    name={
                      if @sort_direction == "asc", do: "hero-chevron-up", else: "hero-chevron-down"
                    }
                    class="w-4 h-4"
                  />
                </span>
              </div>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={item <- @items}
            id={"item-#{item.id}"}
            class="hover:bg-base-200 cursor-pointer"
            data-filterable
            data-filterable-text={item.name <> " " <> (item.description || "")}
            phx-click={@on_click}
            phx-value-id={item.id}
          >
            <td :if={"images" in @visible_fields} class="p-1">
              <img
                :if={has_images?(item)}
                src={get_image_url(item, @media_url_fn)}
                alt={item.name}
                class="w-10 h-10 object-cover rounded"
              />
              <div
                :if={!has_images?(item)}
                class="w-10 h-10 bg-base-300 rounded flex items-center justify-center"
              >
                <.icon name="hero-photo" class="w-5 h-5 text-base-content/30" />
              </div>
            </td>
            <td :for={field <- @visible_fields -- ["images"]}>
              {render_field_value(item, field)}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  # ===========================================================================
  # Card View
  # ===========================================================================

  @doc """
  Renders dataset items in a card grid view.

  ## Attributes
    - items: List of dataset items
    - visible_fields: List of field names to show
    - card_style: "image_overlay" or "metadata"
    - on_click: Event to push when card is clicked
    - on_new: Event for creating a new item (shows + card first)
    - new_label: Label for the new item card
    - media_url_fn: Function to convert image path to full URL
  """
  attr :items, :list, required: true
  attr :visible_fields, :list, default: ["name", "description", "rating"]
  attr :card_style, :string, default: "image_overlay"
  attr :on_click, :string, default: nil
  attr :on_new, :string, default: nil
  attr :new_label, :string, default: "New Item"
  attr :media_url_fn, :any, default: nil
  attr :id, :string, default: "dataset-cards"

  def dataset_card_view(assigns) do
    ~H"""
    <div
      id={@id}
      class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
    >
      <%!-- New item card (first position) --%>
      <.new_item_card
        :if={@on_new}
        id="new-item-card"
        label={@new_label}
        on_click={@on_new}
      />

      <%= if @card_style == "image_overlay" do %>
        <.image_overlay_card
          :for={item <- @items}
          item={item}
          visible_fields={@visible_fields}
          on_click={@on_click}
          media_url_fn={@media_url_fn}
        />
      <% else %>
        <.metadata_card
          :for={item <- @items}
          item={item}
          visible_fields={@visible_fields}
          on_click={@on_click}
        />
      <% end %>
    </div>
    """
  end

  # Image overlay card (for POIs, scenic routes with images)
  # Matches tour card styling with hover zoom effect
  attr :item, :map, required: true
  attr :visible_fields, :list, required: true
  attr :on_click, :string, default: nil
  attr :media_url_fn, :any, default: nil

  defp image_overlay_card(assigns) do
    image_url = get_image_url(assigns.item, assigns.media_url_fn)

    subtitle =
      if "country_code" in assigns.visible_fields do
        get_property(assigns.item, "country_code")
      else
        nil
      end

    description =
      if "description" in assigns.visible_fields do
        assigns.item.description
      else
        nil
      end

    rating =
      if "rating" in assigns.visible_fields do
        assigns.item.rating
      else
        nil
      end

    assigns =
      assigns
      |> assign(:image_url, image_url)
      |> assign(:subtitle, subtitle)
      |> assign(:description, description)
      |> assign(:rating, rating)

    ~H"""
    <div
      id={"card-#{@item.id}"}
      class="group relative aspect-[16/10] rounded overflow-hidden cursor-pointer"
      data-filterable
      data-filterable-text={@item.name <> " " <> (@item.description || "")}
      phx-click={@on_click}
      phx-value-id={@item.id}
    >
      <%!-- Image with hover zoom --%>
      <img
        :if={@image_url}
        src={@image_url}
        alt={@item.name}
        class="absolute inset-0 w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
      />
      <%!-- Placeholder when no image --%>
      <div
        :if={!@image_url}
        class="absolute inset-0 bg-gradient-to-br from-base-300 to-base-200 flex items-center justify-center group-hover:scale-105 transition-transform duration-500"
      >
        <.icon name="hero-photo" class="w-12 h-12 text-base-content/20" />
      </div>

      <%!-- Gradient overlay --%>
      <div class="absolute inset-0 bg-gradient-to-t from-black/85 via-black/35 to-black/10" />

      <%!-- Content overlay --%>
      <div class="absolute inset-x-0 bottom-0 p-4">
        <%!-- Title --%>
        <h3 class="text-lg font-semibold text-white truncate">{@item.name}</h3>
        <%!-- Stars below title --%>
        <div class="flex items-center gap-2 mt-0.5">
          <span :if={@rating} class="text-white text-sm">
            {render_white_stars(@rating)}
          </span>
          <span :if={@subtitle} class="text-sm text-white/70">
            {@subtitle}
          </span>
        </div>
        <%!-- Description appears on hover --%>
        <p
          :if={@description}
          class="text-sm text-white/80 mt-1.5 line-clamp-2 max-h-0 overflow-hidden group-hover:max-h-12 transition-all duration-300 ease-out"
        >
          {@description}
        </p>
      </div>
    </div>
    """
  end

  # Metadata card (for countries, items without images)
  # Uses same aspect ratio and styling as image cards
  attr :item, :map, required: true
  attr :visible_fields, :list, required: true
  attr :on_click, :string, default: nil

  defp metadata_card(assigns) do
    ~H"""
    <div
      id={"card-#{@item.id}"}
      class="group relative aspect-[16/10] rounded overflow-hidden cursor-pointer bg-base-200 hover:bg-base-300 transition-colors"
      data-filterable
      data-filterable-text={@item.name <> " " <> (@item.description || "")}
      phx-click={@on_click}
      phx-value-id={@item.id}
    >
      <div class="absolute inset-0 flex flex-col items-center justify-center p-4 text-center">
        <%!-- Flag emoji or icon --%>
        <div class="text-5xl mb-2">
          {get_property(@item, "flag_emoji") || get_property(@item, "emoji") || ""}
        </div>
        <%!-- Name --%>
        <h3 class="font-semibold text-lg">{@item.name}</h3>
        <%!-- Metadata rows --%>
        <div class="space-y-1 text-sm text-base-content/70 mt-2">
          <p :if={get_property(@item, "continent") && "continent" in @visible_fields}>
            {get_property(@item, "continent")}
          </p>
          <div
            :if={get_property(@item, "safety_rating") && "safety_rating" in @visible_fields}
            class="flex items-center justify-center gap-1"
          >
            {render_safety_dots(get_property(@item, "safety_rating"))}
            <span class="ml-1">{safety_label(get_property(@item, "safety_rating"))}</span>
          </div>
          <p :if={get_property(@item, "driving_side") && "driving_side" in @visible_fields}>
            {String.capitalize(to_string(get_property(@item, "driving_side")))}-hand drive
          </p>
        </div>
      </div>
    </div>
    """
  end

  # ===========================================================================
  # Load More Trigger
  # ===========================================================================

  @doc """
  Renders an invisible trigger element for infinite scroll.
  When this element becomes visible, it triggers loading more items.
  """
  attr :has_more, :boolean, required: true
  attr :loading, :boolean, default: false

  def load_more_trigger(assigns) do
    ~H"""
    <div :if={@has_more} id="load-more-trigger" phx-hook="InfiniteScroll" class="py-4 text-center">
      <span :if={@loading} class="loading loading-spinner loading-md"></span>
      <span :if={!@loading} class="text-base-content/40 text-sm">Scroll for more...</span>
    </div>
    """
  end

  # ===========================================================================
  # Helper Functions
  # ===========================================================================

  defp has_images?(%{images: images}) when is_list(images) and images != [], do: true
  defp has_images?(_), do: false

  defp get_image_url(%{images: [first | _]}, media_url_fn) when is_function(media_url_fn) do
    media_url_fn.(first)
  end

  defp get_image_url(%{images: [first | _]}, _), do: first
  defp get_image_url(_, _), do: nil

  defp get_property(%{properties: props}, key) when is_map(props) do
    Map.get(props, key) || Map.get(props, to_string(key))
  end

  defp get_property(item, key) do
    Map.get(item, key) || Map.get(item, String.to_existing_atom(key))
  rescue
    ArgumentError -> nil
  end

  defp render_stars(nil), do: ""

  defp render_stars(rating) when is_integer(rating) do
    filled = String.duplicate("\u2605", rating)
    empty = String.duplicate("\u2606", 5 - rating)
    filled <> empty
  end

  # White stars for cards with dark backgrounds
  defp render_white_stars(nil), do: ""

  defp render_white_stars(rating) when is_integer(rating) and rating >= 1 and rating <= 5 do
    filled = String.duplicate("\u2605", rating)
    empty = String.duplicate("\u2606", 5 - rating)
    filled <> empty
  end

  defp render_white_stars(_), do: ""

  defp render_safety_dots(nil), do: ""

  defp render_safety_dots(rating) when is_integer(rating) do
    filled = String.duplicate("●", rating)
    empty = String.duplicate("○", 5 - rating)
    filled <> empty
  end

  defp safety_label(1), do: "Dangerous"
  defp safety_label(2), do: "Risky"
  defp safety_label(3), do: "Caution"
  defp safety_label(4), do: "Safe"
  defp safety_label(5), do: "Very Safe"
  defp safety_label(_), do: ""

  defp field_label("name"), do: "Name"
  defp field_label("description"), do: "Description"
  defp field_label("rating"), do: "Rating"
  defp field_label("country_code"), do: "Country"
  defp field_label("continent"), do: "Continent"
  defp field_label("safety_rating"), do: "Safety"
  defp field_label("driving_side"), do: "Driving Side"
  defp field_label("from_port"), do: "From"
  defp field_label("to_port"), do: "To"
  defp field_label("operator"), do: "Operator"
  defp field_label("company"), do: "Company"
  defp field_label("duration"), do: "Duration"
  defp field_label("distance_km"), do: "Distance"
  defp field_label("risk_level"), do: "Risk Level"
  defp field_label("reason"), do: "Reason"
  defp field_label("countries"), do: "Countries"
  defp field_label("route_type"), do: "Type"
  defp field_label(field), do: field |> String.replace("_", " ") |> String.capitalize()

  defp render_field_value(item, "name"), do: item.name
  defp render_field_value(item, "description"), do: truncate(item.description, 50)

  defp render_field_value(item, "rating") do
    if item.rating, do: render_stars(item.rating), else: "-"
  end

  defp render_field_value(item, field) do
    case get_property(item, field) do
      nil -> "-"
      value when is_list(value) -> Enum.join(value, ", ")
      value -> to_string(value)
    end
  end

  defp truncate(nil, _), do: ""
  defp truncate(text, max) when byte_size(text) <= max, do: text
  defp truncate(text, max), do: String.slice(text, 0, max) <> "..."

  # ===========================================================================
  # Settings Modal
  # ===========================================================================

  @doc """
  Renders the full dataset settings modal with tabs for general settings and view preferences.
  """
  attr :dataset, :map, required: true
  attr :view_type, :string, default: "list"
  attr :visible_fields_list, :list, default: ["name", "description", "rating"]
  attr :visible_fields_table, :list, default: ["name", "rating", "country_code"]
  attr :visible_fields_card, :list, default: ["name", "description", "rating", "images"]
  attr :sort_field, :string, default: "name"
  attr :sort_direction, :string, default: "asc"
  attr :default_filter, :string, default: ""
  attr :settings_tab, :string, default: "general"
  attr :can_edit_dataset, :boolean, default: false

  def settings_modal(assigns) do
    # Common fields available for all datasets
    common_fields = [
      {"name", "Name"},
      {"description", "Description"},
      {"images", "Images"}
    ]

    # Build dataset-specific fields from field_schema
    dataset_fields =
      (assigns.dataset.field_schema || [])
      |> Enum.map(fn field ->
        name = field["name"] || ""
        label = field["label"] || String.capitalize(name)
        {name, label}
      end)

    available_fields = common_fields ++ dataset_fields

    assigns = assign(assigns, :available_fields, available_fields)

    ~H"""
    <div
      class="modal modal-open"
      phx-click-away="close_settings"
      phx-window-keydown="close_settings"
      phx-key="escape"
    >
      <div class="modal-box max-w-lg">
        <h3 class="font-bold text-lg mb-4">Dataset Settings</h3>
        <button
          type="button"
          class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
          phx-click="close_settings"
        >
          <.icon name="hero-x-mark" class="w-5 h-5" />
        </button>

        <%!-- Tabs --%>
        <div role="tablist" class="tabs tabs-bordered mb-4">
          <button
            type="button"
            role="tab"
            class={["tab", @settings_tab == "general" && "tab-active"]}
            phx-click="settings_tab"
            phx-value-tab="general"
          >
            General
          </button>
          <button
            type="button"
            role="tab"
            class={["tab", @settings_tab == "views" && "tab-active"]}
            phx-click="settings_tab"
            phx-value-tab="views"
          >
            View Preferences
          </button>
        </div>

        <form phx-submit="save_settings" class="space-y-4">
          <%!-- General Tab --%>
          <div :if={@settings_tab == "general"} class="space-y-4">
            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">Name</span>
              </label>
              <input
                type="text"
                name="dataset_name"
                value={@dataset.name}
                class="input input-bordered input-sm w-full"
                disabled={!@can_edit_dataset || @dataset.is_system}
              />
              <label :if={@dataset.is_system} class="label">
                <span class="label-text-alt text-base-content/50">
                  System datasets cannot be renamed
                </span>
              </label>
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">Description</span>
              </label>
              <textarea
                name="dataset_description"
                class="textarea textarea-bordered textarea-sm w-full h-20"
                disabled={!@can_edit_dataset || @dataset.is_system}
              >{@dataset.description}</textarea>
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">Type</span>
              </label>
              <div class="flex items-center gap-2">
                <span class="badge badge-sm badge-outline">
                  {String.capitalize(@dataset.geometry_type || "point")}
                </span>
                <span :if={@dataset.is_system} class="badge badge-sm badge-primary">System</span>
              </div>
            </div>
          </div>

          <%!-- View Preferences Tab --%>
          <div :if={@settings_tab == "views"} class="space-y-4">
            <%!-- Default View Type --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">Default View</span>
              </label>
              <div class="flex gap-4">
                <label class="label cursor-pointer gap-2">
                  <input
                    type="radio"
                    name="view_type"
                    value="list"
                    class="radio radio-sm"
                    checked={@view_type == "list"}
                  />
                  <span class="label-text">List</span>
                </label>
                <label class="label cursor-pointer gap-2">
                  <input
                    type="radio"
                    name="view_type"
                    value="table"
                    class="radio radio-sm"
                    checked={@view_type == "table"}
                  />
                  <span class="label-text">Table</span>
                </label>
                <label class="label cursor-pointer gap-2">
                  <input
                    type="radio"
                    name="view_type"
                    value="card"
                    class="radio radio-sm"
                    checked={@view_type == "card"}
                  />
                  <span class="label-text">Card</span>
                </label>
              </div>
            </div>

            <%!-- Visible Fields per View --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">Fields to Display</span>
              </label>

              <%!-- List View Fields --%>
              <div class="collapse collapse-arrow bg-base-200 rounded-lg mb-2">
                <input type="checkbox" name="expand-list" checked />
                <div class="collapse-title text-sm font-medium py-2 min-h-0">
                  <.icon name="hero-bars-3" class="w-4 h-4 inline mr-2" /> List View
                </div>
                <div class="collapse-content">
                  <div class="grid grid-cols-2 gap-1 pt-2">
                    <label
                      :for={{field, label} <- @available_fields}
                      class="label cursor-pointer gap-2 py-0.5"
                    >
                      <input
                        type="checkbox"
                        name={"visible_fields_list[#{field}]"}
                        value="true"
                        class="checkbox checkbox-xs"
                        checked={field in @visible_fields_list}
                      />
                      <span class="label-text text-xs flex-1">{label}</span>
                    </label>
                  </div>
                </div>
              </div>

              <%!-- Table View Fields --%>
              <div class="collapse collapse-arrow bg-base-200 rounded-lg mb-2">
                <input type="checkbox" name="expand-table" />
                <div class="collapse-title text-sm font-medium py-2 min-h-0">
                  <.icon name="hero-table-cells" class="w-4 h-4 inline mr-2" /> Table View
                </div>
                <div class="collapse-content">
                  <div class="grid grid-cols-2 gap-1 pt-2">
                    <label
                      :for={{field, label} <- @available_fields}
                      class="label cursor-pointer gap-2 py-0.5"
                    >
                      <input
                        type="checkbox"
                        name={"visible_fields_table[#{field}]"}
                        value="true"
                        class="checkbox checkbox-xs"
                        checked={field in @visible_fields_table}
                      />
                      <span class="label-text text-xs flex-1">{label}</span>
                    </label>
                  </div>
                </div>
              </div>

              <%!-- Card View Fields --%>
              <div class="collapse collapse-arrow bg-base-200 rounded-lg">
                <input type="checkbox" name="expand-card" />
                <div class="collapse-title text-sm font-medium py-2 min-h-0">
                  <.icon name="hero-squares-2x2" class="w-4 h-4 inline mr-2" /> Card View
                </div>
                <div class="collapse-content">
                  <div class="grid grid-cols-2 gap-1 pt-2">
                    <label
                      :for={{field, label} <- @available_fields}
                      class="label cursor-pointer gap-2 py-0.5"
                    >
                      <input
                        type="checkbox"
                        name={"visible_fields_card[#{field}]"}
                        value="true"
                        class="checkbox checkbox-xs"
                        checked={field in @visible_fields_card}
                      />
                      <span class="label-text text-xs flex-1">{label}</span>
                    </label>
                  </div>
                </div>
              </div>
            </div>

            <%!-- Sort --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">Default Sort</span>
              </label>
              <div class="flex gap-2">
                <select name="sort_field" class="select select-bordered select-sm flex-1">
                  <option value="name" selected={@sort_field == "name"}>Name</option>
                  <option value="rating" selected={@sort_field == "rating"}>Rating</option>
                  <option value="position" selected={@sort_field == "position"}>Position</option>
                  <option value="inserted_at" selected={@sort_field == "inserted_at"}>
                    Date Added
                  </option>
                </select>
                <select name="sort_direction" class="select select-bordered select-sm">
                  <option value="asc" selected={@sort_direction == "asc"}>Ascending</option>
                  <option value="desc" selected={@sort_direction == "desc"}>Descending</option>
                </select>
              </div>
            </div>

            <%!-- Default Filter --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">Default Filter</span>
              </label>
              <input
                type="text"
                name="default_filter"
                value={@default_filter}
                placeholder="e.g. UNESCO, Beach, National Park"
                class="input input-bordered input-sm w-full"
              />
              <label class="label">
                <span class="label-text-alt text-base-content/50">
                  Pre-filter items when opening this dataset
                </span>
              </label>
            </div>
          </div>

          <%!-- Actions --%>
          <div class="modal-action">
            <button type="button" class="btn btn-ghost" phx-click="reset_settings">
              Reset to Default
            </button>
            <button type="submit" class="btn btn-primary">
              Save
            </button>
          </div>
        </form>
      </div>
      <div class="modal-backdrop bg-black/50"></div>
    </div>
    """
  end
end
