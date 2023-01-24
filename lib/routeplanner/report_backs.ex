defmodule Routeplanner.ReportBacks do
  @moduledoc """
  The ReportBacks context.
  """

  import Ecto.Query, warn: false
  alias Routeplanner.Repo

  alias Routeplanner.ReportBacks.ReportBack

  @doc """
  Returns the list of report_backs.

  ## Examples

      iex> list_report_backs()
      [%ReportBack{}, ...]

  """
  def list_report_backs do
    Repo.all(ReportBack)
  end

  @doc """
  Gets a single report_back.

  Raises `Ecto.NoResultsError` if the Report back does not exist.

  ## Examples

      iex> get_report_back!(123)
      %ReportBack{}

      iex> get_report_back!(456)
      ** (Ecto.NoResultsError)

  """
  def get_report_back!(id), do: Repo.get!(ReportBack, id)

  @doc """
  Creates a report_back.

  ## Examples

      iex> create_report_back(%{field: value})
      {:ok, %ReportBack{}}

      iex> create_report_back(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_report_back(attrs \\ %{}) do
    %ReportBack{}
    |> ReportBack.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Updates a report_back.

  ## Examples

      iex> update_report_back(report_back, %{field: new_value})
      {:ok, %ReportBack{}}

      iex> update_report_back(report_back, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_report_back(%ReportBack{} = report_back, attrs) do
    report_back
    |> ReportBack.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a report_back.

  ## Examples

      iex> delete_report_back(report_back)
      {:ok, %ReportBack{}}

      iex> delete_report_back(report_back)
      {:error, %Ecto.Changeset{}}

  """
  def delete_report_back(%ReportBack{} = report_back) do
    Repo.delete(report_back)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking report_back changes.

  ## Examples

      iex> change_report_back(report_back)
      %Ecto.Changeset{data: %ReportBack{}}

  """
  def change_report_back(%ReportBack{} = report_back, attrs \\ %{}) do
    ReportBack.changeset(report_back, attrs)
  end

  def find(case_id) do
    Repo.get_by(ReportBack, case_id: case_id)
  end

  def find_or_new(case_id) do
    case find(case_id) do
      nil -> create_report_back(%{ case_id: case_id })
      rpt -> rpt
    end
  end
end
