defmodule Wordlex.GameEngine do
  alias Wordlex.Game

  def new(word_to_guess) do
    %{%Game{} | word: word_to_guess}
  end

  def guesses_left(%Game{} = game) do
    game.allowed_guesses - length(game.guessed_tiles)
  end

  def winner?(tiles) do
    tiles |> Enum.map(fn {_char, condition} -> condition == :correct end) |> Enum.all?()
  end

  def analyze(guess, %Game{word: word}) when guess == word do
    guess |> String.graphemes() |> Enum.map(fn char -> {char, :correct} end)
  end

  def analyze(guess, %Game{word: word}) do
    for {char, index} <- guess |> String.graphemes() |> Enum.with_index() do
      if char == String.at(word, index) do
        {char, :correct}
      else
        if String.contains?(word, char) do
          {char, :incorrect}
        else
          {char, :invalid}
        end
      end
    end
  end

  def resolve(%Game{} = game, guess) do
    tiles = analyze(guess, game)

    if winner?(tiles) do
      %{game | won?: true, guessed_tiles: [tiles] ++ game.guessed_tiles}
    else
      %{game | guessed_tiles: [tiles] ++ game.guessed_tiles}
    end
  end
end
