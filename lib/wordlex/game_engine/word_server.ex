defmodule Wordlex.WordServer do
  use GenServer

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
    {:reply, Enum.random(words), state}
  end

  @impl true
  def handle_call({:valid_guess?, guess}, _from, %{valid_guesses: valid_guesses} = state) do
    {:reply, Enum.member?(valid_guesses, guess), state}
  end
end
