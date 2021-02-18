defmodule PeekTest do
  use ExUnit.Case
  alias PeekTest.Data

  doctest Peek

  describe "peek/2" do
    test "figures out simple module types" do
      %{
        t: {:map,
         [
           # :__struct__ is a magic key
           {{:atom, :__struct__}, {:atom, PeekTest.Data.A}},
           # Types are a union `type | nil`
           {{:atom, :one}, {:union, [:string, {:atom, nil}]}},
           {{:atom, :three}, {:union, [union: [atom: :ok, atom: :error], atom: nil]}},
           {{:atom, :two}, {:union, [atom: :ok, atom: nil]}}
         ]}
      } = Peek.peek Data.A, all_types: true
    end

    test "figures out remote user module types" do
      {:map,
        [
          {{:atom, :__struct__}, {:atom, PeekTest.Data.B}},
          {{:atom, :c},
          {:union,
            [map: [{{:atom, :__struct__}, {:atom, PeekTest.Data.C}}], atom: nil]}}
        ]} = Peek.peek Data.B
    end

    test "strips structs properly" do
      %{
        t: {:map,
         [
           {{:atom, :one}, {:union, [:string, {:atom, nil}]}},
           {{:atom, :three}, {:union, [union: [atom: :ok, atom: :error], atom: nil]}},
           {{:atom, :two}, {:union, [atom: :ok, atom: nil]}}
         ]}
      } = Peek.peek Data.A, filter_structs: true, all_types: true

      {:map,
        [
          {{:atom, :c},
          {:union, [map: [], atom: nil]}}
        ]} = Peek.peek Data.B, filter_structs: true
    end

    test "figures out lists" do
      {:map,
        [
          {{:atom, :__struct__}, {:atom, PeekTest.Data.D}},
          {{:atom, :whatever}, {:union, [list: [:integer], atom: nil]}}
        ]} = Peek.peek Data.D
    end

    test "converts to json properly" do
      %{
        "one" => ["string", "nil"],
        "three" => %{"atom" => ["nil"], "union" => [%{"atom" => ["ok", "error"]}]},
        "two" => %{"atom" => ["ok", "nil"]}
      } = Peek.peek Data.A, json: true
    end

    test "converts remote types to json properly" do
      %{
        "d" => [%{"whatever" => ["integer", "nil"]}, "nil"]
      } = Peek.peek Data.E, json: true
    end

    test "json handles remote types in map keys properly" do
      %{
        "f" => %{
          "atom" => ["nil"],
          "env" => %{"atom" => ["nil"], "string" => "string"}
        }
      } = Peek.peek Data.G, json: true
    end

    test "handles integer() (idk why this happened but yeah)" do
      {
        :map, [
          {{:atom, :__struct__}, {:atom, PeekTest.Data.H}},
          {{:atom, :int}, :integer},
        ],
      } = Peek.peek Data.H
    end
  end
end
