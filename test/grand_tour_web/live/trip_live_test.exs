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

  defp switch_to_trips_tab(live) do
    live |> element("button", "Trips") |> render_click()
  end

  describe "Trip management on Tour Show page without trips" do
    setup [:register_and_log_in_user, :create_tour]

    test "shows empty state when no trips on Trips tab", %{conn: conn, tour: tour} do
      {:ok, show_live, _html} = live(conn, ~p"/tours/#{tour}")

      # Switch to Trips tab
      html = switch_to_trips_tab(show_live)

      assert html =~ "No trips yet"
      assert html =~ "Add Trip"
    end

    test "can create a new trip from Overview", %{conn: conn, tour: tour} do
      {:ok, show_live, _html} = live(conn, ~p"/tours/#{tour}")

      # Add Trip link is on Overview tab
      assert show_live |> element("a", "Add Trip") |> render_click() =~ "New Trip"

      assert_patch(show_live, ~p"/tours/#{tour}/trips/new")

      assert show_live
             |> form("#trip-form", trip: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#trip-form", trip: @create_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/tours/#{tour}")

      html = render(show_live)
      assert html =~ "Trip created successfully"

      # Trip name appears in Trips tab
      html = switch_to_trips_tab(show_live)
      assert html =~ "European Leg"
    end
  end

  describe "Trip management on Tour Show page with trips" do
    setup [:register_and_log_in_user, :create_tour, :create_trip]

    test "displays trip in overview stats", %{conn: conn, tour: tour} do
      {:ok, _show_live, html} = live(conn, ~p"/tours/#{tour}")

      # Overview shows trip count in stats
      assert html =~ "1"
      assert html =~ "Planned segments"
    end

    test "displays trip in Trips tab", %{conn: conn, tour: tour, trip: trip} do
      {:ok, show_live, _html} = live(conn, ~p"/tours/#{tour}")

      # Switch to Trips tab
      html = switch_to_trips_tab(show_live)

      assert html =~ trip.name
      assert html =~ "planning"
      refute html =~ "No trips yet"
    end

    test "can edit a trip", %{conn: conn, tour: tour, trip: trip} do
      {:ok, show_live, _html} = live(conn, ~p"/tours/#{tour}")

      # Switch to Trips tab first
      switch_to_trips_tab(show_live)

      assert show_live
             |> element("#trip-#{trip.id} a[href*='edit']")
             |> render_click() =~ "Edit Trip"

      assert_patch(show_live, ~p"/tours/#{tour}/trips/#{trip}/edit")

      assert show_live
             |> form("#trip-form", trip: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#trip-form", trip: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/tours/#{tour}")

      html = render(show_live)
      assert html =~ "Trip updated successfully"

      # Trip name appears in Trips tab
      html = switch_to_trips_tab(show_live)
      assert html =~ "Updated Trip"
    end

    test "can delete a trip", %{conn: conn, tour: tour, trip: trip} do
      {:ok, show_live, _html} = live(conn, ~p"/tours/#{tour}")

      # Switch to Trips tab first
      switch_to_trips_tab(show_live)

      assert has_element?(show_live, "#trip-#{trip.id}")

      assert show_live
             |> element("#trip-#{trip.id} button[phx-click='delete_trip']")
             |> render_click()

      refute has_element?(show_live, "#trip-#{trip.id}")
    end
  end

  describe "Trip reordering" do
    setup [:register_and_log_in_user, :create_tour]

    test "can move trip up", %{conn: conn, tour: tour} do
      {:ok, trip1} = Tours.create_trip(tour, %{name: "First Trip"})
      {:ok, trip2} = Tours.create_trip(tour, %{name: "Second Trip"})

      {:ok, show_live, _html} = live(conn, ~p"/tours/#{tour}")

      # Switch to Trips tab first
      switch_to_trips_tab(show_live)

      # Trip2 should have move up button
      assert has_element?(
               show_live,
               "#trip-#{trip2.id} button[phx-click='move_trip'][phx-value-direction='up']"
             )

      # Trip1 should not have move up button (it's first)
      refute has_element?(
               show_live,
               "#trip-#{trip1.id} button[phx-click='move_trip'][phx-value-direction='up']"
             )

      # Move trip2 up
      show_live
      |> element("#trip-#{trip2.id} button[phx-click='move_trip'][phx-value-direction='up']")
      |> render_click()

      # After reordering, trip2 should be first (position 1)
      assert Tours.get_trip!(trip2.id).position == 1
      assert Tours.get_trip!(trip1.id).position == 2
    end

    test "can move trip down", %{conn: conn, tour: tour} do
      {:ok, trip1} = Tours.create_trip(tour, %{name: "First Trip"})
      {:ok, trip2} = Tours.create_trip(tour, %{name: "Second Trip"})

      {:ok, show_live, _html} = live(conn, ~p"/tours/#{tour}")

      # Switch to Trips tab first
      switch_to_trips_tab(show_live)

      # Move trip1 down
      show_live
      |> element("#trip-#{trip1.id} button[phx-click='move_trip'][phx-value-direction='down']")
      |> render_click()

      # After reordering, trip1 should be second (position 2)
      assert Tours.get_trip!(trip1.id).position == 2
      assert Tours.get_trip!(trip2.id).position == 1
    end
  end

  describe "Trip with dates" do
    setup [:register_and_log_in_user, :create_tour]

    test "can create trip with dates", %{conn: conn, tour: tour} do
      {:ok, show_live, _html} = live(conn, ~p"/tours/#{tour}")

      show_live |> element("a", "Add Trip") |> render_click()

      assert show_live
             |> form("#trip-form",
               trip: %{
                 name: "Dated Trip",
                 start_date: "2027-02-01",
                 end_date: "2027-04-15"
               }
             )
             |> render_submit()

      assert_patch(show_live, ~p"/tours/#{tour}")

      # Switch to Trips tab to see the trip with dates
      html = switch_to_trips_tab(show_live)
      assert html =~ "Dated Trip"
      assert html =~ "Feb 01"
      assert html =~ "Apr 15, 2027"
    end

    test "validates end date is after start date", %{conn: conn, tour: tour} do
      {:ok, show_live, _html} = live(conn, ~p"/tours/#{tour}")

      show_live |> element("a", "Add Trip") |> render_click()

      assert show_live
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
end
