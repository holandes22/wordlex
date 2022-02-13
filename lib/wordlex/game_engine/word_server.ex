defmodule Wordlex.WordServer do
  use GenServer

  @day_in_seconds 86400
  ## API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def word_to_guess() do
    GenServer.call(__MODULE__, :get_word)
  end

  def valid_guess?(guess) do
    GenServer.call(__MODULE__, {:valid_guess?, guess})
  end

  ## Callbacks

  @impl true
  def init(:ok) do
    words = Path.expand("./words.txt", __DIR__) |> File.read!() |> String.split()
    valid_guesses = Path.expand("./valid_guesses.txt", __DIR__) |> File.read!() |> String.split()
    state = %{words: words, valid_guesses: valid_guesses}
    {:ok, state}
  end

  @impl true
  def handle_call(:get_word, _from, %{words: words} = state) do
    word = get_word_of_the_day(words)
    {:reply, word, state}
  end

  @impl true
  def handle_call({:valid_guess?, guess}, _from, %{valid_guesses: valid_guesses} = state) do
    {:reply, Enum.member?(valid_guesses, guess), state}
  end

  defp get_word_of_the_day(words) do
    # Taken from https://github.com/cwackerfuss/react-wordle/blob/main/src/lib/words.ts#L42
    epoch_in_seconds = ~U[2022-01-01 00:00:00.00Z] |> DateTime.to_unix()
    now_in_seconds = DateTime.now!("Etc/UTC") |> DateTime.to_unix()
    len = length(words)
    index = ((now_in_seconds - epoch_in_seconds) / @day_in_seconds) |> floor() |> rem(len)
    Enum.at(words, index)
  end
end
