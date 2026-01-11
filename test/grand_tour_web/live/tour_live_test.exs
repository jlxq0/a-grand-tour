defmodule GrandTourWeb.TourLiveTest do
  use GrandTourWeb.ConnCase

  import Phoenix.LiveViewTest
  alias GrandTour.Tours

  @create_attrs %{name: "Test Tour", subtitle: "A test tour", is_public: false}
  @update_attrs %{name: "Updated Tour", subtitle: "Updated description", is_public: true}
  @invalid_attrs %{name: nil}

  defp create_tour(%{scope: scope}) do
    {:ok, tour} = Tours.create_tour(scope, @create_attrs)
    %{tour: tour}
  end

  describe "Index without tours" do
    setup [:register_and_log_in_user]

    test "shows empty state when no tours", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/tours")

      assert html =~ "No tours yet"
      assert html =~ "Create Tour"
    end
  end

  describe "Index with tours" do
    setup [:register_and_log_in_user, :create_tour]

    test "lists all tours", %{conn: conn, tour: tour} do
      {:ok, _index_live, html} = live(conn, ~p"/tours")

      assert html =~ "Tours"
      assert html =~ tour.name
    end

    test "saves new tour", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/tours")

      assert index_live |> element("a", "New Tour") |> render_click() =~
               "New Tour"

      assert_patch(index_live, ~p"/tours/new")

      assert index_live
             |> form("#tour-form", tour: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tour-form", tour: %{name: "Brand New Tour", subtitle: "Fresh start"})
             |> render_submit()

      assert_patch(index_live, ~p"/tours")

      html = render(index_live)
      assert html =~ "Tour created successfully"
      assert html =~ "Brand New Tour"
    end

    test "updates tour in listing", %{conn: conn, tour: tour} do
      {:ok, index_live, _html} = live(conn, ~p"/tours")

      assert index_live |> element("#tours-#{tour.id} a", "Edit") |> render_click() =~
               "Edit Tour"

      assert_patch(index_live, ~p"/tours/#{tour}/edit")

      assert index_live
             |> form("#tour-form", tour: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tour-form", tour: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/tours")

      html = render(index_live)
      assert html =~ "Tour updated successfully"
      assert html =~ "Updated Tour"
    end

    test "deletes tour in listing", %{conn: conn, tour: tour} do
      {:ok, index_live, _html} = live(conn, ~p"/tours")

      assert index_live |> element("#tours-#{tour.id} button", "") |> render_click()

      refute has_element?(index_live, "#tours-#{tour.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_tour]

    test "displays tour", %{conn: conn, tour: tour} do
      {:ok, _show_live, html} = live(conn, ~p"/tours/#{tour}")

      assert html =~ tour.name
      assert html =~ tour.subtitle
    end

    test "edit link navigates to edit page", %{conn: conn, tour: tour} do
      {:ok, show_live, _html} = live(conn, ~p"/tours/#{tour}")

      # Edit Tour link navigates to the Index page edit modal
      show_live |> element("a", "Edit Tour") |> render_click()

      assert_redirect(show_live, ~p"/tours/#{tour}/edit")
    end
  end

  describe "Unauthenticated access" do
    test "redirects to login when not logged in", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/tours")
      assert path =~ "/users/log-in"
    end
  end
end
