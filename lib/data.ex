defmodule PeekTest.Data do
  if Mix.env() == :test do
    use TypedStruct

    typedstruct module: A do
      @type test() :: :ok
      @type test_two() :: :ok | :error

      field :one, String.t()
      field :two, test()
      field :three, test_two()
    end

    typedstruct module: B do
      field :c, PeekTest.Data.C.t()
    end

    typedstruct module: C do
    end

    typedstruct module: D do
      field :whatever, [integer()]
    end
  end
end
