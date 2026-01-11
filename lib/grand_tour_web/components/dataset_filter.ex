defmodule GrandTourWeb.DatasetFilter do
  @moduledoc """
  Filter bar component for dataset views.
  Includes search input, filter builder, and view mode toggle.
  """
  use Phoenix.Component

  import GrandTourWeb.CoreComponents, only: [icon: 1]

  @doc """
  Renders the dataset filter bar with search, filter builder, and view toggle.

  ## Attributes
    - view_type: Current view type ("list", "table", "card")
    - filter_value: Current search text
    - item_count: Total number of items
    - available_fields: List of field names available for filtering
    - active_filters: List of active filter conditions (e.g., [%{field: "country_code", op: "equals", value: "US"}])
    - show_filter_builder: Whether the filter builder dropdown is open
    - on_view_change: Event name for view type change
    - on_filter_change: Event name for search filter change
    - on_toggle_filter_builder: Event name to toggle filter builder
    - on_add_filter: Event name to add a filter condition
    - on_remove_filter: Event name to remove a filter condition
  """
  attr :view_type, :string, default: "list"
  attr :filter_value, :string, default: ""
  attr :item_count, :integer, default: 0
  attr :available_fields, :list, default: []
  attr :active_filters, :list, default: []
  attr :show_filter_builder, :boolean, default: false
  attr :on_view_change, :string, default: "switch_view"
  attr :on_filter_change, :string, default: "filter_items"
  attr :on_toggle_filter_builder, :string, default: "toggle_filter_builder"
  attr :on_add_filter, :string, default: "add_filter"
  attr :on_remove_filter, :string, default: "remove_filter"

  def dataset_filter_bar(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 mb-4">
      <div class="flex gap-2 items-center">
        <%!-- Search input --%>
        <form class="relative flex-1 max-w-md" phx-change={@on_filter_change}>
          <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none z-10">
            <.icon name="hero-magnifying-glass" class="w-4 h-4 text-base-content/60" />
          </div>
          <input
            type="text"
            id="dataset-filter-input"
            name="filter"
            value={@filter_value}
            placeholder={"Search #{@item_count} items"}
            class={[
              "input input-bordered input-sm w-full pl-10",
              @filter_value != "" && "pr-8"
            ]}
            phx-hook="QuickFilter"
            phx-debounce="300"
            autocomplete="off"
          />
          <button
            :if={@filter_value != ""}
            type="button"
            class="absolute inset-y-0 right-0 pr-3 flex items-center"
            phx-click={@on_filter_change}
            phx-value-filter=""
          >
            <.icon name="hero-x-mark" class="w-4 h-4 text-base-content/40 hover:text-base-content" />
          </button>
        </form>

        <%!-- Filter builder button --%>
        <div class="relative">
          <button
            type="button"
            class={[
              "btn btn-sm btn-ghost",
              @show_filter_builder && "btn-active",
              @active_filters != [] && "text-primary"
            ]}
            phx-click={@on_toggle_filter_builder}
            title="Filter builder"
          >
            <.icon name="hero-funnel" class="w-4 h-4" />
            <span :if={@active_filters != []} class="badge badge-primary badge-xs">
              {length(@active_filters)}
            </span>
          </button>

          <%!-- Filter builder dropdown --%>
          <.filter_builder_dropdown
            :if={@show_filter_builder}
            available_fields={@available_fields}
            on_add_filter={@on_add_filter}
            on_close={@on_toggle_filter_builder}
          />
        </div>

        <%!-- View toggle buttons --%>
        <div class="flex gap-0.5 bg-base-200 rounded-lg p-0.5">
          <button
            type="button"
            class={[
              "btn btn-xs btn-ghost px-2",
              @view_type == "list" && "btn-active"
            ]}
            phx-click={@on_view_change}
            phx-value-view="list"
            title="List view"
          >
            <.icon name="hero-bars-3" class="w-4 h-4" />
          </button>
          <button
            type="button"
            class={[
              "btn btn-xs btn-ghost px-2",
              @view_type == "table" && "btn-active"
            ]}
            phx-click={@on_view_change}
            phx-value-view="table"
            title="Table view"
          >
            <.icon name="hero-table-cells" class="w-4 h-4" />
          </button>
          <button
            type="button"
            class={[
              "btn btn-xs btn-ghost px-2",
              @view_type == "card" && "btn-active"
            ]}
            phx-click={@on_view_change}
            phx-value-view="card"
            title="Card view"
          >
            <.icon name="hero-squares-2x2" class="w-4 h-4" />
          </button>
        </div>
      </div>

      <%!-- Active filters display --%>
      <div :if={@active_filters != []} class="flex flex-wrap gap-1.5">
        <div
          :for={{filter, index} <- Enum.with_index(@active_filters)}
          class="badge badge-outline gap-1 pr-1"
        >
          <span class="font-medium">{humanize_field(filter.field)}</span>
          <span class="text-base-content/60">{filter.op}</span>
          <span class="text-primary">"{filter.value}"</span>
          <button
            type="button"
            class="hover:text-error"
            phx-click={@on_remove_filter}
            phx-value-index={index}
          >
            <.icon name="hero-x-mark" class="w-3 h-3" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Filter builder dropdown component.
  """
  attr :available_fields, :list, required: true
  attr :on_add_filter, :string, required: true
  attr :on_close, :string, required: true

  def filter_builder_dropdown(assigns) do
    ~H"""
    <div class="absolute right-0 top-full mt-1 z-50 w-72 bg-base-100 rounded-lg shadow-xl border border-base-300">
      <div class="p-3">
        <div class="flex items-center justify-between mb-3">
          <span class="font-medium text-sm">Add Filter</span>
          <button type="button" class="btn btn-ghost btn-xs" phx-click={@on_close}>
            <.icon name="hero-x-mark" class="w-4 h-4" />
          </button>
        </div>

        <form phx-submit={@on_add_filter} class="space-y-2">
          <div>
            <label class="label py-1">
              <span class="label-text text-xs">Field</span>
            </label>
            <select name="field" class="select select-bordered select-sm w-full" required>
              <option value="">Select field...</option>
              <option :for={field <- @available_fields} value={field}>
                {humanize_field(field)}
              </option>
            </select>
          </div>

          <div>
            <label class="label py-1">
              <span class="label-text text-xs">Condition</span>
            </label>
            <select name="op" class="select select-bordered select-sm w-full">
              <option value="contains">contains</option>
              <option value="equals">equals</option>
              <option value="starts_with">starts with</option>
              <option value="ends_with">ends with</option>
              <option value="greater_than">greater than</option>
              <option value="less_than">less than</option>
            </select>
          </div>

          <div>
            <label class="label py-1">
              <span class="label-text text-xs">Value</span>
            </label>
            <input
              type="text"
              name="value"
              class="input input-bordered input-sm w-full"
              placeholder="Enter value..."
              required
            />
          </div>

          <button type="submit" class="btn btn-primary btn-sm w-full mt-2">
            <.icon name="hero-plus" class="w-4 h-4" /> Add Filter
          </button>
        </form>
      </div>
    </div>
    """
  end

  @doc """
  Renders a compact version of the filter bar for mobile or smaller spaces.
  """
  attr :view_type, :string, default: "list"
  attr :on_view_change, :string, default: "switch_view"

  def compact_view_toggle(assigns) do
    ~H"""
    <div class="flex gap-0.5 bg-base-200 rounded-lg p-0.5">
      <button
        type="button"
        class={["btn btn-xs btn-ghost px-2", @view_type == "list" && "btn-active"]}
        phx-click={@on_view_change}
        phx-value-view="list"
      >
        <.icon name="hero-bars-3" class="w-4 h-4" />
      </button>
      <button
        type="button"
        class={["btn btn-xs btn-ghost px-2", @view_type == "table" && "btn-active"]}
        phx-click={@on_view_change}
        phx-value-view="table"
      >
        <.icon name="hero-table-cells" class="w-4 h-4" />
      </button>
      <button
        type="button"
        class={["btn btn-xs btn-ghost px-2", @view_type == "card" && "btn-active"]}
        phx-click={@on_view_change}
        phx-value-view="card"
      >
        <.icon name="hero-squares-2x2" class="w-4 h-4" />
      </button>
    </div>
    """
  end

  # Helpers

  defp humanize_field(field) when is_binary(field) do
    # Convert camelCase or snake_case to Title Case
    field
    # Insert space before capitals (camelCase)
    |> String.replace(~r/([a-z])([A-Z])/, "\\1 \\2")
    # Replace underscores with spaces (snake_case)
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp humanize_field(field), do: to_string(field)
end
