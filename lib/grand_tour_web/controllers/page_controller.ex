defmodule GrandTourWeb.PageController do
  use GrandTourWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
