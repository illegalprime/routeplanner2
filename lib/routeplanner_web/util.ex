defmodule RouteplannerWeb.Util do
  def to_unix(nil), do: nil
  def to_unix(date), do: DateTime.to_unix(date)

  def qr_code(text) do
    text
    |> QRCode.create(:high)
    |> Result.and_then(&QRCode.Svg.to_base64/1)
  end

  def ok(socket), do: {:ok, socket}
  def noreply(socket), do: {:noreply, socket}
end
