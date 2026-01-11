defmodule GrandTourWeb.AppLiveTest do
  use GrandTourWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "AppLive" do
    test "renders the main app layout", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      # Check header
      assert html =~ "A Grand Tour"

      # Check tabs are present
      assert html =~ "Overview"
      assert html =~ "Timeline"
      assert html =~ "Trips"
      assert html =~ "Documents"

      # Check default tab content (Overview)
      assert html =~ "Your 13-year overland expedition"
    end

    test "switches between tabs", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Switch to Timeline tab
      html = view |> element("button", "Timeline") |> render_click()
      assert html =~ "Visual timeline of your journey"

      # Switch to Trips tab
      html = view |> element("button", "Trips") |> render_click()
      assert html =~ "Manage your trips and routes"

      # Switch to Documents tab
      html = view |> element("button", "Documents") |> render_click()
      assert html =~ "Your trip notes and documentation"

      # Switch back to Overview
      html = view |> element("button", "Overview") |> render_click()
      assert html =~ "Your 13-year overland expedition"
    end

    test "has split view layout structure", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      # Check for map and content panels
      assert html =~ "id=\"map-panel\""
      assert html =~ "id=\"content-panel\""
      assert html =~ "id=\"divider\""
    end
  end
end
