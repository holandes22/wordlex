defmodule Wordlex.Game do
  defstruct guessed_tiles: [], won?: false, allowed_guesses: 6, word: nil
end
