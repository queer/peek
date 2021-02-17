defmodule Peek do
  @moduledoc """
  Peek at typespecs in a module and get them in a more-usable format.
  """

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
      Peek.peek MyApp.Module, :my_type

      # Filter out the `:__struct__` key for cleaner output
      Peek.peek MyApp.Module, :t, filter_structs: true

  ## Options

  - `filter_structs`: Whether or not to filter out the `:__struct__` key.
                      Defaults to `false`.
  """
  @spec peek(Module.t(), atom(), Keyword.t()) :: map()
  def peek(module, type \\ :t, opts \\ []) when is_atom(module) and is_atom(type) do
    # TODO: Allow a list of types or smth idk
    filter_structs? = Keyword.get opts, :filter_structs, false

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
    |> finalise(filter_structs?)
  end

  defp finalise(data, filter_structs?) do
    if filter_structs? do
      data
      |> Enum.map(fn {k, v} ->
        {k, filter_structs(v)}
      end)
      |> Map.new
    else
      data
    end
  end

  defp filter_structs({type, value}) when type in [:map, :list, :union] do
    {type, filter_structs(value)}
  end

  defp filter_structs(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list
    |> filter_structs
    |> List.to_tuple
  end

  defp filter_structs(value) when is_list(value) do
    value
    |> Enum.reject(fn
      {{:atom, :__struct__}, _} -> true
      _ -> false
    end)
    |> Enum.map(&filter_structs/1)
  end

  defp filter_structs(map) when is_map(map) do
    map
    |> Enum.reject(fn
      {_, {{:atom, :__struct__}, _}} -> true
      _ -> false
    end)
    |> Enum.map(fn {k, v} ->
      {k, filter_structs(v)}
    end)
    |> Map.new
  end

  defp filter_structs(value) do
    value
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
    module |> peek(user_type) |> Map.get(user_type)
  end

  defp process_type_ast(_module, {:remote_type, _line, [{:atom, _, String}, {:atom, _, :t}, _type_args]}) do
    # TODO: Process type args too
    :string
  end

  defp process_type_ast(_module, {:remote_type, _line, [{:atom, _, remote_module}, {:atom, _, type_name}, _type_args]}) do
    # TODO: Process type args too
    remote_module |> peek(type_name) |> Map.get(type_name)
  end

  defp process_type_ast(_module, {:remote_type, [{:atom, _, remote_module}, {:atom, _, type_name}, _type_args], _default}) do
    # TODO: Process type args too
    remote_module |> peek(type_name) |> Map.get(type_name)
  end

  defp process_type_ast(_module, {:type, _line, type_name, []}) when type_name in @builtins do
    type_name
  end

  defp process_type_ast(_module, {kind, _line, value}) when is_atom(kind) and kind in @builtins do
    {kind, value}
  end
end
