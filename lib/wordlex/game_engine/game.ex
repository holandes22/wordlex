defmodule Wordlex.Game do
  @enforce_keys [:word]
  @derive Jason.Encoder
  defstruct guesses: [], result: :playing, allowed_guesses: 6, word: nil, over?: false

  @type guess() :: {String.t(), :correct | :incorrect | :invalid | :empty}

  @type t() :: %__MODULE__{
          guesses: list(guess),
          result: :playing | :lost | :won,
          allowed_guesses: Integer.t(),
          word: String.t() | nil,
          over?: Boolean.t()
        }

  @spec new(String.t()) :: t()
  def new(word_to_guess) do
    %__MODULE__{word: word_to_guess}
  end
end
