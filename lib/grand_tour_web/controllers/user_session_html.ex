defmodule GrandTourWeb.UserSessionHTML do
  use GrandTourWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:grand_tour, GrandTour.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
