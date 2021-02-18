defmodule Peek.Transform do
  #############
  ## FILTERS ##
  #############

  def filter({type, value}, filter) when type in [:map, :list, :union] do
    {type, filter(value, filter)}
  end

  def filter(tuple, filter) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list
    |> filter(filter)
    |> List.to_tuple
  end

  def filter(value, filter) when is_list(value) do
    value
    |> Enum.filter(filter)
    |> Enum.map(&filter(&1, filter))
  end

  def filter(map, filter) when is_map(map) do
    map
    |> Enum.filter(filter)
    |> Enum.map(fn {k, v} ->
      {k, filter(v, filter)}
    end)
    |> Map.new
  end

  def filter(value, _filter) do
    value
  end

  ##########
  ## JSON ##
  ##########

  def json({type, value}) when type in [:list, :union] do
    json(value)
  end

  def json({:map, value}) do
    value
    |> Enum.map(fn {k, v} ->
      {json_map_key(k), json(v)}
    end)
    |> Map.new
  end

  def json(value) when is_map(value) do
    value
    |> Enum.map(fn {k, v} ->
      {json_map_key(k), json(v)}
    end)
    |> Map.new
  end

  def json(value) when is_list(value) do
    if Keyword.keyword?(value) do
      kw_to_multimap value
    else
      Enum.map value, &json/1
    end
  end

  def json({:atom, value}) when value in [nil, true, false] do
    Atom.to_string value
  end

  def json(value) when is_tuple(value) do
    value |> Tuple.to_list |> Enum.map(&json/1)
  end

  def json(value) do
    cond do
      is_atom(value) -> Atom.to_string value
      is_number(value) and value < 9007199254740991 -> value
      is_number(value) -> to_string value
      true ->
        case value do
          {:atom, atom} -> Atom.to_string atom
          _ -> value
        end
    end
  end

  defp json_map_key({:atom, value}), do: Atom.to_string value
  defp json_map_key(value) when is_atom(value), do: Atom.to_string value
  defp json_map_key(value), do: value

  defp kw_to_multimap([list: [list_value], atom: nil]) do
    json {json(list_value), json(nil)}
  end
  defp kw_to_multimap(kw) when is_list(kw) do
    Enum.reduce kw, %{}, fn
      {:map, _} = map, acc ->
        mapped = json map
        Map.merge acc, mapped

      {k, v}, acc ->
        k = json_map_key k
        v = json v

        if Map.has_key?(acc, k) do
          %{acc | k => acc[k] ++ [v]}
        else
          Map.put acc, k, [v]
        end
    end
  end
end
