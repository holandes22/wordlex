defmodule Wordlex.GameEngine do
  alias Wordlex.Game

  def new(word_to_guess) do
    %{%Game{} | word: normalize(word_to_guess)}
  end

  def guesses_left(%Game{} = game) do
    game.allowed_guesses - length(game.guesses)
  end

  def winner?(tiles) do
    tiles |> Enum.map(fn {_char, condition} -> condition == :correct end) |> Enum.all?()
  end

  def won?(game), do: game.result == :won

  def analyze(%Game{word: word}, guess) when guess == word do
    guess |> normalize() |> String.graphemes() |> Enum.map(fn char -> {char, :correct} end)
  end

  def analyze(%Game{word: word}, guess) do
    guess = normalize(guess)

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

  def resolve(%Game{result: :playing} = game, guess) do
    tiles = analyze(game, guess)
    game = %{game | guesses: [tiles] ++ game.guesses}

    result =
      if winner?(tiles) do
        :won
      else
        if guesses_left(game) > 0 do
          :playing
        else
          :lost
        end
      end

    %{game | result: result}
  end

  def resolve(%Game{} = game, _guess), do: game

  def letter_map(%Game{guesses: guesses}) do
    normalize = fn l -> l |> Enum.uniq() |> Enum.sort() end

    map =
      guesses
      |> List.flatten()
      |> Enum.reduce(%{correct: [], incorrect: [], invalid: []}, fn {char, state}, acc ->
        case state do
          :correct -> %{acc | correct: normalize.([char | acc.correct])}
          :incorrect -> %{acc | incorrect: normalize.([char | acc.incorrect])}
          :invalid -> %{acc | invalid: normalize.([char | acc.invalid])}
        end
      end)

    # correct wins over incorrect, so if a letter appears in both,
    # we need to remove it from that list
    incorrect = Enum.filter(map.incorrect, fn letter -> !Enum.member?(map.correct, letter) end)
    %{map | incorrect: incorrect}
  end

  defp normalize(guess) when is_binary(guess), do: String.upcase(guess)
end
