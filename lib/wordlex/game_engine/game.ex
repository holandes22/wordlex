defmodule Wordlex.Game do
  defstruct guesses: [], result: :playing, allowed_guesses: 6, word: nil, locked?: false
end
