defmodule GrandTourWeb.LandingLiveTest do
  use GrandTourWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "LandingLive" do
    test "renders the landing page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      # Check hero section
      assert html =~ "A Grand Tour"
      assert html =~ "Plan your epic overland journey"

      # Check call-to-action buttons
      assert html =~ "Get Started"
      assert html =~ "Sign In"
    end

    test "has feature cards", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      # Check feature cards
      assert html =~ "Interactive Maps"
      assert html =~ "Trip Planning"
      assert html =~ "Documentation"
    end

    test "has registration call to action", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Ready to Start Your Adventure?"
      assert html =~ "Create Your First Tour"
    end
  end
end
