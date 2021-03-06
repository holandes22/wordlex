defmodule Wordlex.WordServer do
  use GenServer
  alias Wordlex.Constants

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
    state = %{words: Constants.words(), valid_guesses: Constants.valid_guesses()}
    {:ok, state}
  end

  @impl true
  def handle_call(:get_word, _from, %{words: words} = state) do
    word = get_word_of_the_day(words)
    {:reply, word, state}
  end

  @impl true
  def handle_call({:valid_guess?, guess}, _from, state) do
    guess = String.downcase(guess)
    valid? = Enum.member?(state.words, guess) || Enum.member?(state.valid_guesses, guess)
    {:reply, valid?, state}
  end

  def get_word_of_the_day(words, opts \\ []) do
    # Taken from https://github.com/cwackerfuss/react-wordle/blob/main/src/lib/words.ts#L42
    epoch_in_seconds =
      Keyword.get(opts, :epoch_in_seconds) || ~U[2022-01-01 00:00:00.00Z] |> DateTime.to_unix()

    now_in_seconds =
      Keyword.get(opts, :now_in_seconds) || "Etc/UTC" |> DateTime.now!() |> DateTime.to_unix()

    len = length(words)
    index = ((now_in_seconds - epoch_in_seconds) / @day_in_seconds) |> floor() |> rem(len)
    Enum.at(words, index)
  end
end
