defmodule Peek do
  @moduledoc """
  Peek at typespecs in a module and get them in a more-usable format.
  """

  alias Peek.Transform

  @builtins [
    :binary,
    :integer,
    :non_neg_integer,
    :atom,
  ]

  @doc """
  Peek at a type in a module.

  ## Usage

      # Defaults to `:t`
      Peek.peek MyApp.Module

      # Check a specific type
      Peek.peek MyApp.Module, type: :my_type

      # Filter out the `:__struct__` key for cleaner output
      Peek.peek MyApp.Module, filter_structs: true

  ## Options

  - `type`: The type to get info for. Defaults to `:t`.
  - `filter_structs`: Whether or not to filter out the `:__struct__` key.
    Defaults to `false`.
  - `all_types`: Whether or not to return a map of all types. Defaults to
    `false`.
  - `json`: Whether or not to return a JSON-safe value. Defaults to `false`.
  """
  @spec peek(atom(), Keyword.t()) :: map()
  def peek(module, opts \\ []) when is_atom(module) do
    type = Keyword.get opts, :type, :t
    filter_structs? = Keyword.get opts, :filter_structs, false
    all_types? = Keyword.get opts, :all_types, false
    json? = Keyword.get opts, :json, false

    {:ok, types} = Code.Typespec.fetch_types module

    types
    |> Enum.filter(fn
      {:type, _data} -> true
      _ -> false
    end)
    |> Enum.map(fn {:type, data} -> data end)
    |> Enum.filter(fn
      {^type, _, _} -> true
      _ -> false
    end)
    |> Enum.map(&process_type(module, &1))
    |> Map.new
    |> finalise(type, all_types?, filter_structs?, json?)
  end

  defp finalise(data, type, all_types?, filter_structs?, json?) do
    data
    |> case do
      data when filter_structs? or json? ->
        data
        |> Enum.map(fn {k, v} ->
          {k, Transform.filter(v, fn
            {{:atom, :__struct__}, _} -> false
              _ -> true
          end)}
        end)
        |> Map.new

      data -> data
    end
    |> case do
      data when all_types? -> data
      data when is_map(data) -> data[type]
      data -> data
    end
    |> case do
      data when json? -> Transform.json data
      data -> data
    end
  end

  defp process_type(module, {type_name, type_ast, _unknown}) do
    {type_name, process_type_ast(module, type_ast)}
  end

  defp process_type_ast(module, {:type, _line, :union, union_members}) when is_list(union_members) do
    {:union, Enum.map(union_members, &process_type_ast(module, &1))}
  end

  defp process_type_ast(module, {:type, _line, :map, map_fields}) do
    {:map, Enum.map(map_fields, &process_type_ast(module, &1))}
  end

  defp process_type_ast(module, {:type, _line, :list, types}) do
    {:list, Enum.map(types, &process_type_ast(module, &1))}
  end

  defp process_type_ast(_module, {:type, _line, :map_field_exact, [{key_type, _, key}, {value_type, _, value}]}) do
    {{key_type, key}, {value_type, value}}
  end

  defp process_type_ast(module, {:type, _line, :map_field_exact, [{key_type, _, key}, {:type, _, :union, union_members}]}) do
    processed_union = process_type_ast module, {:type, 0, :union, union_members}
    {{key_type, key}, processed_union}
  end

  defp process_type_ast(module, {:user_type, _line, user_type, _user_type_args}) do
    # TODO: Process type args too
    module
    |> peek(type: user_type)
    |> case do
      data when is_map(data) -> Map.get data, user_type
      data -> data
    end
  end

  defp process_type_ast(_module, {:remote_type, _line, [{:atom, _, String}, {:atom, _, :t}, _type_args]}) do
    # TODO: Process type args too
    :string
  end

  defp process_type_ast(_module, {:remote_type, _line, [{:atom, _, remote_module}, {:atom, _, type_name}, _type_args]}) do
    # TODO: Process type args too
    remote_module
    |> peek(type: type_name)
    |> case do
      data when is_map(data) -> Map.get data, type_name
      data -> data
    end
  end

  defp process_type_ast(_module, {:remote_type, [{:atom, _, remote_module}, {:atom, _, type_name}, _type_args], _default}) do
    # TODO: Process type args too
    remote_module
    |> peek(type: type_name)
    |> case do
      data when is_map(data) -> Map.get data, type_name
      data -> data
    end
  end

  defp process_type_ast(_module, {:type, _line, type_name, []}) when type_name in @builtins do
    type_name
  end

  defp process_type_ast(_module, {kind, _line, value}) when is_atom(kind) and kind in @builtins do
    {kind, value}
  end
end
