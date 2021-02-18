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

    typedstruct module: E do
      field :d, [PeekTest.Data.D.t()]
    end

    typedstruct module: F do
      field :env, %{required(String.t()) => String.t()}
    end

    typedstruct module: G do
      field :f, PeekTest.Data.F.t()
    end

    typedstruct module: H do
      field :int, integer(), default: 0
    end
  end
end
