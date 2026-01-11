defmodule GrandTourWeb.TourLiveTest do
  use GrandTourWeb.ConnCase

  import Phoenix.LiveViewTest
  alias GrandTour.Tours

  @create_attrs %{name: "Test Tour", subtitle: "A test tour", is_public: false}
  @invalid_attrs %{name: nil}

  defp create_tour(%{scope: scope}) do
    {:ok, tour} = Tours.create_tour(scope, @create_attrs)
    %{tour: tour}
  end

  describe "Index without tours" do
    setup [:register_and_log_in_user]

    test "shows empty state when no tours", %{conn: conn, user: user} do
      {:ok, _index_live, html} = live(conn, ~p"/#{user.username}/tours")

      assert html =~ "Start Your Journey"
      assert html =~ "Create Tour"
    end

    test "redirects from /tours to /:username/tours", %{conn: conn, user: user} do
      {:error, {:live_redirect, %{to: path}}} = live(conn, ~p"/tours")
      assert path == "/#{user.username}/tours"
    end
  end

  describe "Index with tours" do
    setup [:register_and_log_in_user, :create_tour]

    test "lists all tours", %{conn: conn, tour: tour, user: user} do
      {:ok, _index_live, html} = live(conn, ~p"/#{user.username}/tours")

      assert html =~ tour.name
    end

    test "saves new tour", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/#{user.username}/tours")

      assert index_live |> element("#new-tour-card") |> render_click() =~
               "New Tour"

      assert_patch(index_live, ~p"/#{user.username}/tours/new")

      assert index_live
             |> form("#tour-form", tour: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tour-form", tour: %{name: "Brand New Tour", subtitle: "Fresh start"})
             |> render_submit()

      # After save, navigates to the new tour's page
      {_path, flash} = assert_redirect(index_live)
      assert flash["info"] == "Tour created successfully"
    end

    test "clicking tour navigates to show page", %{conn: conn, tour: tour, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/#{user.username}/tours")

      index_live |> element("#tours-#{tour.id}") |> render_click()

      assert_redirect(index_live, ~p"/#{user.username}/#{tour.slug}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_tour]

    test "displays tour", %{conn: conn, tour: tour, user: user} do
      {:ok, _show_live, html} = live(conn, ~p"/#{user.username}/#{tour.slug}")

      assert html =~ tour.name
      assert html =~ tour.subtitle
    end
  end

  describe "Unauthenticated access" do
    test "redirects to login when not logged in", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/tours")
      assert path =~ "/users/log-in"
    end
  end
end
