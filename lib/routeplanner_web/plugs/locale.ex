defmodule RouteplannerWeb.Plugs.Locale do
  import Plug.Conn

  @locales ["en", "fr", "de"]

  def init(default), do: default

  def call(%Plug.Conn{params: %{"locale" => loc}} = conn, _default) when loc in @locales do
    IO.puts "Locale is #{loc}"
    assign(conn, :locale, loc)
  end

  def call(conn, default) do
    IO.puts "Locale is #{default}"
    assign(conn, :locale, default)
  end
end
