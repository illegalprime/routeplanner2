defmodule Routeplanner.ReportBacks.ReportBack do
  use Ecto.Schema
  import Ecto.Changeset
  alias Routeplanner.CourtCases

  schema "report_backs" do
    field :case_id, :string
    field :email, :string
    field :followup, :boolean, default: false
    field :knocked, :boolean, default: false
    field :notes, :string
    field :phone, :string
    field :talked, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(report_back, attrs) do
    report_back
    |> cast(attrs, [:case_id, :phone, :email, :notes, :knocked, :talked, :followup])
    |> validate_required([:case_id])
    |> unique_constraint(:case_id)
    |> validate_case_exist()
  end

  def validate_case_exist(cs) do
    case CourtCases.by_id(get_field(cs, :case_id)) do
      nil -> add_error(cs, :case_id, "case not found")
      _ -> cs
    end
  end
end
