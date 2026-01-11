defmodule GrandTourWeb.SharedComponents do
  @moduledoc """
  Shared UI components used across the application.
  Provides consistent styling for cards, headers, and other common elements.
  """
  use Phoenix.Component

  import GrandTourWeb.CoreComponents, only: [icon: 1]

  # ===========================================================================
  # Section Header
  # ===========================================================================

  @doc """
  Renders a section header with title and optional edit button on hover.
  Matches the tour overview header styling.

  ## Attributes
    - title: The header text
    - edit_event: Event to fire when edit button is clicked (optional)
    - subtitle: Optional subtitle text
  """
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :edit_event, :string, default: nil

  def section_header(assigns) do
    ~H"""
    <div class="mb-4">
      <div class="group/title flex items-center gap-2">
        <h1 class="text-3xl font-bold">{@title}</h1>
        <button
          :if={@edit_event}
          type="button"
          class="opacity-0 group-hover/title:opacity-100 transition-opacity"
          phx-click={@edit_event}
          title="Settings"
        >
          <.icon name="hero-pencil" class="w-5 h-5 text-base-content/50 hover:text-primary" />
        </button>
      </div>
      <p :if={@subtitle} class="text-lg text-base-content/70 mt-1">
        {@subtitle}
      </p>
    </div>
    """
  end

  # ===========================================================================
  # Image Card
  # ===========================================================================

  @doc """
  Renders a card with image, gradient overlay, and text.
  Matches the tour card styling with hover zoom effect.

  ## Attributes
    - id: Unique identifier for the card
    - image_url: URL of the image (or nil for placeholder)
    - title: Card title
    - subtitle: Optional subtitle (shown below title)
    - rating: Optional rating (1-5 stars)
    - description: Optional description (shown on hover)
    - on_click: Event name when card is clicked
    - click_value: Value to pass with click event
    - badge: Optional badge text (e.g., "Public")
  """
  attr :id, :string, required: true
  attr :image_url, :string, default: nil
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :rating, :integer, default: nil
  attr :description, :string, default: nil
  attr :on_click, :string, default: nil
  attr :click_value, :any, default: nil
  attr :badge, :string, default: nil
  attr :class, :string, default: nil

  def image_card(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "group relative aspect-[16/10] rounded overflow-hidden cursor-pointer",
        @class
      ]}
      phx-click={@on_click}
      phx-value-id={@click_value}
    >
      <%!-- Image with hover zoom --%>
      <img
        :if={@image_url}
        src={@image_url}
        alt={@title}
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
      <div class="absolute inset-0 p-4 flex flex-col justify-between">
        <%!-- Top: Badge --%>
        <div class="flex justify-end">
          <span
            :if={@badge}
            class="text-xs px-2 py-0.5 bg-white/20 backdrop-blur-sm text-white rounded"
          >
            {@badge}
          </span>
        </div>

        <%!-- Bottom: Title, rating, description --%>
        <div>
          <div class="flex items-center justify-between gap-2">
            <h3 class="text-xl font-semibold text-white truncate">{@title}</h3>
            <span :if={@rating} class="text-white text-sm flex-shrink-0">
              {render_white_stars(@rating)}
            </span>
          </div>
          <p :if={@subtitle} class="text-sm text-white/80 mt-1 line-clamp-1">
            {@subtitle}
          </p>
          <%!-- Description on hover with fade-in --%>
          <p
            :if={@description}
            class="text-sm text-white/70 mt-2 line-clamp-2 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
          >
            {@description}
          </p>
        </div>
      </div>
    </div>
    """
  end

  # ===========================================================================
  # New Item Card (+ button)
  # ===========================================================================

  @doc """
  Renders a card with a + button for creating new items.
  Matches the "New Tour" card styling.

  ## Attributes
    - id: Unique identifier
    - label: Text below the + icon
    - on_click: Event name when clicked
  """
  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :on_click, :string, default: nil
  attr :navigate, :string, default: nil
  attr :class, :string, default: nil

  def new_item_card(assigns) do
    ~H"""
    <div
      :if={@on_click}
      id={@id}
      class={[
        "group relative aspect-[16/10] rounded overflow-hidden bg-base-200 hover:bg-base-300 transition-colors cursor-pointer",
        @class
      ]}
      phx-click={@on_click}
    >
      <div class="absolute inset-0 flex flex-col items-center justify-center">
        <.icon
          name="hero-plus"
          class="w-8 h-8 text-base-content/30 group-hover:text-base-content/50 transition-colors"
        />
        <span class="text-sm text-base-content/40 group-hover:text-base-content/60 mt-2 transition-colors">
          {@label}
        </span>
      </div>
    </div>
    <.link
      :if={@navigate && !@on_click}
      id={@id}
      navigate={@navigate}
      class={[
        "group relative aspect-[16/10] rounded overflow-hidden bg-base-200 hover:bg-base-300 transition-colors cursor-pointer block",
        @class
      ]}
    >
      <div class="absolute inset-0 flex flex-col items-center justify-center">
        <.icon
          name="hero-plus"
          class="w-8 h-8 text-base-content/30 group-hover:text-base-content/50 transition-colors"
        />
        <span class="text-sm text-base-content/40 group-hover:text-base-content/60 mt-2 transition-colors">
          {@label}
        </span>
      </div>
    </.link>
    """
  end

  # ===========================================================================
  # Helpers
  # ===========================================================================

  defp render_white_stars(nil), do: ""

  defp render_white_stars(rating) when is_integer(rating) and rating >= 1 and rating <= 5 do
    filled = String.duplicate("\u2605", rating)
    empty = String.duplicate("\u2606", 5 - rating)
    filled <> empty
  end

  defp render_white_stars(_), do: ""
end
