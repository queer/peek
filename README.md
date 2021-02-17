# Peek

Parse out typespecs on your modules to create human-legible type data.

Sample input/output:

```Elixir
defmodule A do
  use TypedStruct

  typedstruct do
    @type test() :: :ok
    @type test_two() :: :ok | :error

    field :one, String.t()
    field :two, test()
    field :three, test_two()
  end
end

Peek.peek A
# returns
%{
  t: {:map,
    [
      # :__struct__ is a magic key
      {{:atom, :__struct__}, {:atom, A}},
      # Types are a union `type | nil`
      {{:atom, :one}, {:union, [:string, {:atom, nil}]}},
      {{:atom, :three}, {:union, [union: [atom: :ok, atom: :error], atom: nil]}},
      {{:atom, :two}, {:union, [atom: :ok, atom: nil]}}
    ]}
}

```

Examples are difficult, so check out [test/peek_test.exs](https://github.com/queer/peek/blob/master/test/peek_test.exs)
to see some more.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `peek` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:peek, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/peek](https://hexdocs.pm/peek).

