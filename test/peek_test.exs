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
      } = Peek.peek Data.A
    end

    test "figures out remote user module types" do
      %{
        t: {:map,
         [
           {{:atom, :__struct__}, {:atom, PeekTest.Data.B}},
           {{:atom, :c},
            {:union,
             [map: [{{:atom, :__struct__}, {:atom, PeekTest.Data.C}}], atom: nil]}}
         ]}
      } = Peek.peek Data.B
    end

    test "strips structs properly" do
      %{
        t: {:map,
         [
           {{:atom, :one}, {:union, [:string, {:atom, nil}]}},
           {{:atom, :three}, {:union, [union: [atom: :ok, atom: :error], atom: nil]}},
           {{:atom, :two}, {:union, [atom: :ok, atom: nil]}}
         ]}
      } = Peek.peek Data.A, :t, filter_structs: true

      %{
        t: {:map,
         [
           {{:atom, :c},
            {:union, [map: [], atom: nil]}}
         ]}
      } = Peek.peek Data.B, :t, filter_structs: true
    end

    test "figures out lists" do
      %{
        t: {:map,
         [
           {{:atom, :__struct__}, {:atom, PeekTest.Data.D}},
           {{:atom, :whatever}, {:union, [list: [:integer], atom: nil]}}
         ]}
      } = Peek.peek Data.D
    end
  end
end
