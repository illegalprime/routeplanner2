defmodule Routeplanner.TravellingSalesmen do
  @path Application.get_env(:routeplanner, __MODULE__)[:tsp_bin_path]

  def solve(matrix) do
    {:ok, json} = Jason.encode(matrix)
    {data, 0} = System.cmd(@path, [json])
    {:ok, result} = Jason.decode(data)
    result
  end
end
