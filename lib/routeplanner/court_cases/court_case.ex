defmodule Routeplanner.CourtCases.CourtCase do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset

  schema "court_cases" do
    field :case_id, :string

    field :name, :string
    field :plaintiff, :string

    field :longitude, :float
    field :latitude, :float
    field :address, :string
    field :street, :string
    field :city, :string
    field :state, :string
    field :zip, :integer

    field :status, :string
    field :judgement, :string
    field :type, :string
    field :file_date, :date
    field :next_event_date, :string
    field :docket, :string

    field :visited, :boolean
    field :active, :boolean

    timestamps()
  end

  @doc false
  def new(court_case, attrs) do
    court_case
    |> changeset(convert_date(attrs))
    |> put_change(:visited, false)
    |> put_change(:active, false)
  end

  def changeset(court_case, attrs) do
    court_case
    |> cast(attrs, [
      :case_id, :name, :plaintiff,
      :longitude, :latitude, :address, :street, :city, :state, :zip,
      :status, :judgement, :type, :file_date, :next_event_date, :docket,
      :visited, :active
    ])
    |> validate_required([
      :case_id, :name, :plaintiff,
      :longitude, :latitude, :address, :street, :city, :state, :zip,
      :status, :judgement, :type, :file_date, :next_event_date, :docket,
    ])
    |> unique_constraint(:case_id)
  end

  def convert_date(attrs) do
    Logger.warn("#{inspect(attrs)}")
    {:ok, date} = attrs["file_date"]
    |> String.split("/")
    |> Enum.map(&String.to_integer/1)
    |> (fn [month, day, year] -> Date.new(year, month, day) end).()
    %{ attrs | "file_date" => date }
  end
end
