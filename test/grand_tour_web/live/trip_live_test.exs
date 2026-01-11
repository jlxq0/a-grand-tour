defmodule GrandTourWeb.TripLiveTest do
  use GrandTourWeb.ConnCase

  import Phoenix.LiveViewTest
  alias GrandTour.Tours

  @create_attrs %{name: "European Leg", subtitle: "Through Western Europe"}
  @update_attrs %{name: "Updated Trip", subtitle: "Updated description", status: "active"}
  @invalid_attrs %{name: nil}

  defp create_tour(%{scope: scope}) do
    {:ok, tour} = Tours.create_tour(scope, %{name: "Test Tour", subtitle: "A test tour"})
    %{tour: tour}
  end

  defp create_trip(%{tour: tour}) do
    {:ok, trip} = Tours.create_trip(tour, @create_attrs)
    %{trip: trip}
  end

  describe "Trip page" do
    setup [:register_and_log_in_user, :create_tour, :create_trip]

    test "displays trip details", %{conn: conn, tour: tour, trip: trip, user: user} do
      {:ok, _live, html} = live(conn, ~p"/#{user.username}/#{tour.slug}/trips/#{trip.slug}")

      assert html =~ trip.name
      assert html =~ trip.subtitle
    end

    test "can navigate from tour overview to trip via dropdown", %{
      conn: conn,
      tour: tour,
      trip: trip,
      user: user
    } do
      {:ok, live, _html} = live(conn, ~p"/#{user.username}/#{tour.slug}")

      # Click on trip in dropdown should navigate
      live |> element("a[href*='trips/#{trip.slug}']") |> render_click()

      assert_redirect(live, ~p"/#{user.username}/#{tour.slug}/trips/#{trip.slug}")
    end
  end

  describe "Creating trips" do
    setup [:register_and_log_in_user, :create_tour]

    test "can create a new trip", %{conn: conn, tour: tour, user: user} do
      {:ok, live, _html} = live(conn, ~p"/#{user.username}/#{tour.slug}/trips/new")

      assert render(live) =~ "New Trip"

      assert live
             |> form("#trip-form", trip: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert live
             |> form("#trip-form", trip: @create_attrs)
             |> render_submit()

      {_path, flash} = assert_redirect(live)
      assert flash["info"] == "Trip created successfully"
    end

    test "can create trip with dates", %{conn: conn, tour: tour, user: user} do
      {:ok, live, _html} = live(conn, ~p"/#{user.username}/#{tour.slug}/trips/new")

      assert live
             |> form("#trip-form",
               trip: %{
                 name: "Dated Trip",
                 start_date: "2027-02-01",
                 end_date: "2027-04-15"
               }
             )
             |> render_submit()

      {_path, flash} = assert_redirect(live)
      assert flash["info"] == "Trip created successfully"

      # Verify the trip was created with correct dates
      trip = Tours.get_trip_by_slug!(tour, "dated-trip")
      assert trip.start_date == ~D[2027-02-01]
      assert trip.end_date == ~D[2027-04-15]
    end

    test "validates end date is after start date", %{conn: conn, tour: tour, user: user} do
      {:ok, live, _html} = live(conn, ~p"/#{user.username}/#{tour.slug}/trips/new")

      assert live
             |> form("#trip-form",
               trip: %{
                 name: "Bad Dates",
                 start_date: "2027-04-15",
                 end_date: "2027-02-01"
               }
             )
             |> render_change() =~ "must be after start date"
    end
  end

  describe "Editing trips" do
    setup [:register_and_log_in_user, :create_tour, :create_trip]

    test "can edit a trip", %{conn: conn, tour: tour, trip: trip, user: user} do
      {:ok, live, _html} = live(conn, ~p"/#{user.username}/#{tour.slug}/trips/#{trip.slug}/edit")

      assert render(live) =~ "Edit Trip"

      assert live
             |> form("#trip-form", trip: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert live
             |> form("#trip-form", trip: @update_attrs)
             |> render_submit()

      {_path, flash} = assert_redirect(live)
      assert flash["info"] == "Trip updated successfully"

      # Verify trip was updated
      updated = Tours.get_trip!(trip.id)
      assert updated.name == "Updated Trip"
      assert updated.status == "active"
    end
  end

  # Note: Trip deletion and reordering UI was removed with the URL restructuring.
  # These functions are tested at the context level in trips_test.exs.
  # UI for these features will be added later to individual trip pages.
end
