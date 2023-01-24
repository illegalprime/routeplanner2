defmodule RouteplannerWeb.Live.Route do
  require Logger
  use RouteplannerWeb, :live_view

  alias Routeplanner.Repo
  alias Routeplanner.CourtCases
  alias Routeplanner.CourtCases.CourtCase
  alias Routeplanner.ReportBacks

  @impl true
  def mount(%{"route" => route}, _session, socket) do
    route = Routeplanner.Routes.find(route)
    cases = Enum.map(route.cases, &CourtCases.by_id/1)
    notes = Enum.map(route.cases, &ReportBacks.find_or_new/1)
    chngs = Enum.map(notes, &ReportBacks.change_report_back/1)
    forms = route.cases |> Enum.zip(Enum.zip(notes, chngs)) |> Enum.into(%{})
    route = Map.put(route, :cases, cases)
    {:ok, cases_json} = cases
    |> Enum.map(&CourtCase.to_encodable/1)
    |> Jason.encode()

    socket
    |> assign(route: route)
    |> assign(cases_json: cases_json)
    |> assign(form_link: "https://gbtu.xyz/report-back")
    |> assign(title: route.name)
    |> assign(report_backs: forms)
    |> ok()
  end

  @impl true
  def handle_event(
    "save",
    %{"report_back" => rb},
    %{assigns: %{report_backs: rbs}} = socket
  ) do
    {report_back, _} = rbs[rb["case_id"]]

    changeset = ReportBacks.change_report_back(report_back, rb)
    |> Map.put(:action, :update)

    report_back = Repo.update!(changeset)

    socket
    |> assign(report_backs: %{rbs | rb["case_id"] => {report_back, changeset}})
    |> noreply()
  end

  #
  # View Functions
  #

  def to_clock(secs) do
    secs
    |> (fn secs -> [trunc(secs / 60), rem(trunc(secs), 60)] end).()
    |> Enum.map(&Integer.to_string/1)
    |> Enum.map(fn s -> String.pad_leading(s, 2, "0") end)
    |> Enum.join(":")
  end

  def qr_code(text) do
    text
    |> QRCode.create(:high)
    |> Result.and_then(&QRCode.Svg.to_base64/1)
  end

  def to_address(cc) do
    "#{cc.street} #{cc.city}, #{cc.state} #{cc.zip}"
  end

  def maybe_date(date) do
    case String.split(date, "/") |> Enum.map(&Integer.parse/1) do
      [{mm, ""}, {dd, ""}, {yyyy, ""}] -> Date.new!(yyyy, mm, dd)
      _ -> nil
    end
  end

  def fmt_date(date) do
    raw(Calendar.strftime(date, "%b.&nbsp;%d, %Y"))
  end

  def ellipsize(name) do
    case String.split(name, ~r/\s+/, parts: 3) do
      [a, b, _] -> "#{a} #{b}…"
      _ -> name
    end
  end

  def ok(socket), do: {:ok, socket}
  def noreply(socket), do: {:noreply, socket}
end
