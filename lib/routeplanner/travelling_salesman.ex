defmodule Routeplanner.TravellingSalesmen do
  def tsp_path() do
    Application.get_env(:routeplanner, __MODULE__)[:tsp_bin_path]
  end

  def solve(matrix) do
    {:ok, json} = Jason.encode(matrix)
    {data, 0} = System.cmd(tsp_path(), [json])
    {:ok, result} = Jason.decode(data)
    result
  end
end
