defmodule RouteplannerWeb.RoutesPageView do
  use RouteplannerWeb, :view

  def qr_code(text) do
    text
    |> QRCode.create(:high)
    |> Result.and_then(&QRCode.Svg.to_base64/1)
  end

  def get_link(conn, route) do
    Routes.live_url(conn, RouteplannerWeb.Live.Route, route.name)
  end
end
