defmodule Wordlex.Stats do
  @derive Jason.Encoder
  defstruct current_streak: 0,
            max_streak: 0,
            lost: 0,
            guess_distribution: %{
              1 => 0,
              2 => 0,
              3 => 0,
              4 => 0,
              5 => 0,
              6 => 0
            }

  @type t() :: %__MODULE__{
          current_streak: Integer.t(),
          max_streak: Integer.t(),
          lost: Integer.t(),
          guess_distribution: %{
            1 => Integer.t(),
            2 => Integer.t(),
            3 => Integer.t(),
            4 => Integer.t(),
            5 => Integer.t(),
            6 => Integer.t()
          }
        }

  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end
end
