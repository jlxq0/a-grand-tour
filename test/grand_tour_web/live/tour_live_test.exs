defmodule GrandTourWeb.TourLiveTest do
  use GrandTourWeb.ConnCase

  import Phoenix.LiveViewTest
  alias GrandTour.Tours

  @create_attrs %{name: "Test Tour", subtitle: "A test tour", is_public: false}
  @update_attrs %{name: "Updated Tour", subtitle: "Updated description", is_public: true}
  @invalid_attrs %{name: nil}

  defp create_tour(_) do
    {:ok, tour} = Tours.create_tour(@create_attrs)
    %{tour: tour}
  end

  describe "Index without tours" do
    test "shows empty state when no tours", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/tours")

      assert html =~ "No tours yet"
      assert html =~ "Create Tour"
    end
  end

  describe "Index with tours" do
    setup [:create_tour]

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
    setup [:create_tour]

    test "displays tour", %{conn: conn, tour: tour} do
      {:ok, _show_live, html} = live(conn, ~p"/tours/#{tour}")

      assert html =~ tour.name
      assert html =~ tour.subtitle
    end

    test "updates tour within modal", %{conn: conn, tour: tour} do
      {:ok, show_live, _html} = live(conn, ~p"/tours/#{tour}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Tour"

      assert_patch(show_live, ~p"/tours/#{tour}/show/edit")

      assert show_live
             |> form("#tour-form", tour: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#tour-form", tour: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/tours/#{tour}")

      html = render(show_live)
      assert html =~ "Tour updated successfully"
      assert html =~ "Updated Tour"
    end
  end
end
