defmodule Wordlex.Settings do
  @derive Jason.Encoder
  defstruct theme: :light

  @type t() :: %__MODULE__{
          theme: :dark | :light
        }

  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end
end
