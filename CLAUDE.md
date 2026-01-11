# CLAUDE.md

Technical reference for Claude Code when working on the Grand Tour project.

## Project Overview

**A Grand Tour** is a multi-tenant trip planning SaaS application for planning long-term overland expeditions. Users can create tours spanning multiple trips, manage points of interest, plan routes, and create documentation.

**Domain:** a-grand-tour.com
**Stack:** Elixir/Phoenix 1.8, LiveView, PostgreSQL + PostGIS, Cloudflare R2

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Backend | Elixir 1.19+ / Phoenix 1.8 | Web framework |
| Real-time | Phoenix LiveView | Interactive UI without JS |
| Database | PostgreSQL 16+ with PostGIS | Spatial data storage |
| Background Jobs | Oban | Route generation, image processing |
| File Storage | Cloudflare R2 | Images, exports |
| Maps | Mapbox GL JS | Globe visualization |
| CSS | Tailwind CSS + DaisyUI | Styling |
| Testing | ExUnit | Unit and integration tests |

## Project Structure

```
lib/
├── grand_tour/              # Business logic (contexts)
│   ├── accounts/            # Users, authentication
│   ├── tours/               # Tours, trips, routes
│   ├── places/              # POIs, countries, scenic routes
│   ├── documents/           # Markdown documents
│   └── geo/                 # GeoJSON handling, PostGIS helpers
│
├── grand_tour_web/          # Web layer
│   ├── live/                # LiveView modules
│   ├── components/          # Reusable components
│   └── controllers/         # Traditional controllers (API, exports)
│
_old/                        # Original prototype data (for seeding)
├── data/                    # GeoJSON files, images
├── scripts/                 # Build scripts
└── *.md                     # Original documentation
```

## Data Model

### Core Entities

```
User
├── id (uuid)
├── email, password_hash
├── name, avatar
└── subscription_tier

Tour
├── id (uuid)
├── user_id (owner)
├── name, subtitle
├── is_public
├── collaborators (many-to-many with users)
└── timestamps

Trip
├── id (uuid)
├── tour_id
├── position (order in tour)
├── name, subtitle
├── start_date, end_date
└── status (planning, active, completed)

Route
├── id (uuid)
├── trip_id
├── segments (jsonb array of typed segments)
├── waypoints (PostGIS MultiPoint)
├── path_simplified (PostGIS LineString, ~1000 points)
├── total_distance_km, total_duration_hrs
└── timestamps

Segment types in Route.segments:
- drive: {type, waypoints, road_type, path}
- ferry: {type, from_port, to_port, operator, path}
- flight: {type, from_airport, to_airport, airline, path}
- train: {type, from_station, to_station, operator, path}
- shipping: {type, from_port, to_port, company, path}

Itinerary
├── id (uuid)
├── trip_id
└── days (has_many ItineraryDay)

ItineraryDay
├── id (uuid)
├── itinerary_id
├── date (or day_number)
├── stops (jsonb array)
├── accommodation
├── notes
└── expenses (jsonb)

Document
├── id (uuid)
├── tour_id
├── type (overview, custom, country_notes, trip_summary)
├── title
├── content (markdown with [[references]])
├── is_auto_generated
└── timestamps
```

### Reference Data (Global, Admin-Maintained)

```
Country
├── code (pk, e.g., "US")
├── name, native_name
├── flag_emoji
├── continent
├── safety_rating (1-5)
├── driving_side (left/right)
├── currency_code
├── power_socket, power_voltage
├── languages (array)
├── time_zones (array)
├── carnet_required
├── notes (markdown)
└── visa_info (jsonb, keyed by passport country)

POI (Point of Interest)
├── id (uuid)
├── name
├── country_code
├── category, subcategory
├── global_rating (1-5 stars)
├── description
├── location (PostGIS Point)
├── images (array of R2 URLs)
└── source (wikipedia, wikivoyage, user, etc.)

ScenicRoute
├── id (uuid)
├── name
├── country_code
├── rating (1-5)
├── description
├── path (PostGIS LineString)
├── images
└── distance_km

Ferry
├── id (uuid)
├── name
├── from_port, to_port
├── country_codes (array)
├── operator
├── path (PostGIS LineString)
└── typical_duration, typical_cost

RiskRegion
├── id (uuid)
├── name
├── risk_level (impossible, problematic)
├── reason
├── area (PostGIS Polygon)
└── updated_at
```

### User Customizations (Per-Tour Overrides)

```
TourPOI (user's custom/modified POIs)
├── id (uuid)
├── tour_id
├── base_poi_id (nullable, if override of global)
├── ... (same fields as POI)
├── is_deleted (soft-delete global POI for this tour)
└── user_rating

TourCountryOverride
├── id (uuid)
├── tour_id
├── country_code
├── safety_rating_override
├── notes_override
└── visa_info_override
```

## GeoJSON Storage Strategy

Large route geometries are handled with multi-resolution storage:

1. **Waypoints**: User-defined stops (10-100 points) - always in DB
2. **Simplified Path**: For map overview (~1,000 points) - in PostGIS
3. **Detailed Path**: Full resolution (~100,000 points) - in PostGIS, lazy-loaded

```sql
-- Example: Simplified geometry for display
SELECT ST_Simplify(path_full, 0.01) as path_display FROM routes;

-- Example: Find POIs near a route
SELECT * FROM pois
WHERE ST_DWithin(location, route.path_simplified, 50000); -- 50km buffer
```

## Development Workflow

**IMPORTANT:** Follow this cycle for every change:

```
1. Implement small feature/fix
2. Write tests (unit + integration)
3. Run validation loop until clean:
   $ mix format
   $ mix compile --warnings-as-errors
   $ mix test
   $ mix format  # again if compile changed anything
4. Check Tidewave MCP for clean logs
5. Test in browser with Playwright MCP
6. Show to user for approval
7. Only after approval: git commit && git push
8. Next iteration
```

### Commands

```bash
# Development
mix phx.server              # Start server
iex -S mix phx.server       # Start with IEx

# Database
mix ecto.create             # Create DB
mix ecto.migrate            # Run migrations
mix ecto.reset              # Drop + create + migrate + seed

# Testing
mix test                    # Run all tests
mix test path/to/test.exs   # Run specific test
mix test --cover            # With coverage

# Code Quality
mix format                  # Format code
mix compile --warnings-as-errors  # Strict compilation
mix credo                   # Static analysis (if added)
```

## LiveView + Mapbox Integration

The map is integrated via LiveView hooks:

```javascript
// assets/js/hooks/map_hook.js
export const MapHook = {
  mounted() {
    this.map = new mapboxgl.Map({...});

    // Map → LiveView
    this.map.on('click', (e) => {
      this.pushEvent("map_clicked", {lng: e.lngLat.lng, lat: e.lngLat.lat});
    });

    // LiveView → Map
    this.handleEvent("fly_to", ({lng, lat, zoom}) => {
      this.map.flyTo({center: [lng, lat], zoom});
    });

    this.handleEvent("update_route", ({geojson}) => {
      this.map.getSource('route').setData(geojson);
    });
  }
};
```

## Document Reference Syntax

Markdown documents support smart references:

```markdown
We'll visit [[country:JO|Jordan]] and see [[poi:petra|Petra]].
Check [[trip:1|Trip 1]] for details.
See [[doc:carnet|Carnet Guide]] for vehicle import.
```

Parsed into clickable links that:
- Highlight the referenced item on the map
- Navigate to the referenced content
- Show preview on hover

## Environment Variables

```bash
# Required
DATABASE_URL=postgresql://user:pass@localhost/grand_tour_dev
SECRET_KEY_BASE=...
MAPBOX_ACCESS_TOKEN=pk....

# R2 Storage
R2_ACCOUNT_ID=...
R2_ACCESS_KEY_ID=...
R2_SECRET_ACCESS_KEY=...
R2_BUCKET_NAME=grand-tour-assets

# Optional
PHX_HOST=a-grand-tour.com
PORT=4000
```

## Key Architectural Decisions

1. **Multi-resolution routes**: Waypoints + simplified + detailed paths, all in PostGIS
2. **Layered data**: Global reference data + per-tour overrides
3. **LiveView-first**: All interactivity via LiveView, JS only for Mapbox
4. **Document-centric**: Everything renders as navigable documents
5. **Background jobs**: Route generation, image processing via Oban
6. **UUIDs everywhere**: Binary IDs for all entities
7. **Storage-agnostic files**: S3-compatible API only (R2, Backblaze B2, MinIO, etc.)

## Image Upload Flow

We do NOT use Cloudflare Images or any vendor-specific image service. Instead:

1. **Upload**: Browser uploads directly to R2 via presigned URL
2. **Process**: Oban job fetches original, generates variants using `image` library:
   - `thumb` (150x150, cropped square)
   - `medium` (800px wide)
   - `large` (1600px wide)
   - `original` (preserved)
3. **Store**: Processed variants uploaded back to R2
4. **Serve**: URLs stored in DB, served directly from R2 (or via CDN)

This approach:
- Works with any S3-compatible storage (easy migration to Backblaze B2, etc.)
- Keeps processing in our control
- Allows custom variants per use case

## Seeding Reference Data

Original data is in `_old/data/`:

```bash
# Seed from original GeoJSON files
mix run priv/repo/seeds/countries.exs
mix run priv/repo/seeds/pois.exs
mix run priv/repo/seeds/scenic_routes.exs
mix run priv/repo/seeds/ferries.exs
mix run priv/repo/seeds/risk_regions.exs
```

## File Locations

- Migrations: `priv/repo/migrations/`
- Seeds: `priv/repo/seeds/`
- Static assets: `priv/static/`
- JS hooks: `assets/js/hooks/`
- Test fixtures: `test/support/fixtures/`

---

## Phoenix 1.8 Guidelines

### Layout & Components

- **Always** begin LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `GrandTourWeb.Layouts` module is aliased in `grand_tour_web.ex`, use without re-aliasing
- Phoenix v1.8 moved `<.flash_group>` to the `Layouts` module — **never** call it outside `layouts.ex`
- **Always** use the `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for icons
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex`

### Routes & Scopes

- Router `scope` blocks include an optional alias prefixed for all routes within
- You **never** need to create your own `alias` for route definitions:

```elixir
scope "/admin", GrandTourWeb.Admin do
  pipe_through :browser
  live "/users", UserLive, :index  # Points to GrandTourWeb.Admin.UserLive
end
```

### HTTP Requests

- Use the included `:req` (`Req`) library for HTTP requests
- **Avoid** `:httpoison`, `:tesla`, and `:httpc`

---

## Elixir Guidelines

### Lists & Variables

- Elixir lists **do not support index-based access** via `mylist[i]`
- **Always** use `Enum.at/2`, pattern matching, or `List` functions:

```elixir
# INVALID
mylist[0]

# VALID
Enum.at(mylist, 0)
```

- Variables are immutable but can be rebound — **must** bind result of block expressions:

```elixir
# INVALID - rebinding inside `if` doesn't work
if connected?(socket) do
  socket = assign(socket, :val, val)
end

# VALID - rebind the result
socket =
  if connected?(socket) do
    assign(socket, :val, val)
  else
    socket
  end
```

### Best Practices

- **Never** nest multiple modules in the same file (causes cyclic dependencies)
- **Never** use map access syntax (`changeset[:field]`) on structs — use `my_struct.field`
- Use `Ecto.Changeset.get_field/2` for changeset field access
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Predicate functions should end in `?` (not start with `is_`)
- Use `Task.async_stream/3` for concurrent enumeration with `timeout: :infinity`

---

## Ecto Guidelines

- **Always** preload associations in queries when accessed in templates
- Remember `import Ecto.Query` in seeds and scripts
- Schema fields use `:string` type even for text columns
- `validate_number/2` does **not** support `:allow_nil` option
- Use `Ecto.Changeset.get_field(changeset, :field)` to access fields
- Fields set programmatically (e.g., `user_id`) must **not** be in `cast` — set explicitly
- **Always** use `mix ecto.gen.migration migration_name` to generate migrations

---

## HEEx Template Guidelines

### Basics

- **Always** use `~H` sigil or `.html.heex` files, **never** `~E`
- **Always** use `Phoenix.Component.form/1` and `to_form/2`, **never** `Phoenix.HTML.form_for`
- **Always** add unique DOM IDs to key elements for testing

### Interpolation

- Use `{...}` for interpolation in attributes and simple values
- Use `<%= ... %>` for block constructs (if, cond, case, for) in tag bodies:

```heex
<div id={@id}>
  {@my_assign}
  <%= if @condition do %>
    {@value}
  <% end %>
</div>
```

### Conditionals

- Elixir does **NOT** support `else if` or `elsif` — **always** use `cond` or `case`:

```heex
<%= cond do %>
  <% @status == :active -> %>
    Active
  <% @status == :pending -> %>
    Pending
  <% true -> %>
    Unknown
<% end %>
```

### Class Lists

- **Always** use list syntax for multiple/conditional classes:

```heex
<a class={[
  "px-2 text-white",
  @active && "bg-blue-500",
  if(@error, do: "border-red-500", else: "border-gray-300")
]}>
```

### Code Blocks

- Use `phx-no-curly-interpolation` for literal curly braces in code snippets:

```heex
<code phx-no-curly-interpolation>
  let obj = {key: "val"}
</code>
```

### Loops

- **Never** use `<% Enum.each %>` — **always** use `<%= for item <- @collection do %>`
- Use HEEx comments: `<%!-- comment --%>`

---

## LiveView Guidelines

### Navigation

- **Never** use deprecated `live_redirect` and `live_patch`
- **Always** use `<.link navigate={href}>` and `<.link patch={href}>` in templates
- Use `push_navigate` and `push_patch` in LiveViews

### Naming & Structure

- LiveViews named like `GrandTourWeb.TourLive` with `Live` suffix
- **Avoid LiveComponents** unless specifically needed
- Routes in `:browser` scope are aliased: `live "/tours", TourLive`

### Streams

- **Always** use streams for collections to avoid memory issues:

```elixir
# Basic operations
stream(socket, :messages, [new_msg])           # append
stream(socket, :messages, items, reset: true)  # reset
stream(socket, :messages, [msg], at: -1)       # prepend
stream_delete(socket, :messages, msg)          # delete
```

- Template setup:

```heex
<div id="messages" phx-update="stream">
  <div :for={{id, msg} <- @streams.messages} id={id}>
    {msg.text}
  </div>
</div>
```

- Streams are **not enumerable** — to filter, refetch and reset:

```elixir
messages = list_messages(filter)
socket |> stream(:messages, messages, reset: true)
```

- **Never** use deprecated `phx-update="append"` or `phx-update="prepend"`

### JS Hooks

- External hooks in `assets/js/` passed to LiveSocket:

```javascript
const MapHook = {
  mounted() { ... }
}
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { MapHook }
});
```

- Colocated hooks use `.` prefix and `:type={Phoenix.LiveView.ColocatedHook}`:

```heex
<input phx-hook=".PhoneNumber" />
<script :type={Phoenix.LiveView.ColocatedHook} name=".PhoneNumber">
  export default {
    mounted() { ... }
  }
</script>
```

- **Always** set `phx-update="ignore"` when hook manages its own DOM
- **Always** provide unique DOM id alongside `phx-hook`

### Events

```elixir
# Push to client
{:noreply, push_event(socket, "my_event", %{data: value})}
```

```javascript
// Handle in hook
this.handleEvent("my_event", data => console.log(data));

// Push to server with reply
this.pushEvent("my_event", {one: 1}, reply => console.log(reply));
```

### Forms

- **Always** use `to_form/2` and assign to `@form`
- **Always** use `<.form for={@form}>` and `<.input field={@form[:field]}>`
- **Never** pass changeset directly to template

```elixir
# In LiveView
{:noreply, assign(socket, form: to_form(changeset))}
```

```heex
<%!-- In template --%>
<.form for={@form} id="tour-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:name]} type="text" />
</.form>
```

---

## Test Guidelines

- **Always** use `start_supervised!/1` to start processes (guarantees cleanup)
- **Avoid** `Process.sleep/1` — use `Process.monitor/1` and assert on `:DOWN`
- Use `:sys.get_state/1` to synchronize before assertions
- **Always** reference element IDs in tests with `has_element?/2`, `element/2`
- Test outcomes, not implementation details
- Debug with `LazyHTML`:

```elixir
html = render(view)
document = LazyHTML.from_fragment(html)
matches = LazyHTML.filter(document, "your-selector")
IO.inspect(matches)
```

---

## Tailwind CSS v4

The `app.css` uses new import syntax:

```css
@import "tailwindcss" source(none);
@source "../css";
@source "../js";
@source "../../lib/grand_tour_web";
```

- **Never** use `@apply`
- **Never** use external script `src` or link `href` in layouts — import into app.js/app.css
- **Never** write inline `<script>` tags in templates
