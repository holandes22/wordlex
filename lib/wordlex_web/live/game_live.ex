defmodule WordlexWeb.GameLive do
  use WordlexWeb, :live_view

  alias Wordlex.{GameEngine, WordServer}
  alias WordlexWeb.Components.Game

  def mount(_params, _session, socket) do
    word_to_guess = WordServer.word_to_guess()
    game = GameEngine.new(word_to_guess)
    game = game |> GameEngine.resolve("tugre") |> GameEngine.resolve("flock")
    next_guess = []
    guesses = Enum.reverse([pad_guess(next_guess) | game.guesses])
    grid = populate_grid(guesses)
    {:ok, assign(socket, game: game, grid: grid, next_guess: next_guess)}
  end

  def render(assigns) do
    ~H"""
    <div phx-window-keydown="key">
      <div><%= @game.word %></div>
      <Game.tile_grid grid={@grid} />
      <Game.keyboard />
    </div>
    """
  end

  def handle_event("key", %{"key" => "Backspace"}, socket) do
    {_element, next_guess} = List.pop_at(socket.assigns.next_guess, -1)
    guesses = Enum.reverse([pad_guess(next_guess) | socket.assigns.game.guesses])
    grid = populate_grid(guesses)
    {:noreply, assign(socket, next_guess: next_guess, grid: grid)}
  end

  def handle_event("key", %{"key" => "Enter"}, socket) do
    next_guess = socket.assigns.next_guess

    if length(next_guess) == 5 do
      guess = socket.assigns.next_guess |> Enum.map(fn {char, _state} -> char end) |> Enum.join()
      game = GameEngine.resolve(socket.assigns.game, guess)
      next_guess = []
      guesses = Enum.reverse([pad_guess(next_guess) | game.guesses])
      grid = populate_grid(guesses)

      socket =
        if GameEngine.won?(game) do
          put_flash(socket, :info, "Success!")
        else
          socket
        end

      {:noreply, assign(socket, game: game, grid: grid, next_guess: next_guess)}
    else
      {:noreply, put_flash(socket, :error, "Guess should be complete")}
    end
  end

  def handle_event("key", %{"key" => key}, socket) do
    next_guess = socket.assigns.next_guess

    socket =
      if String.match?(key, ~r/^[[:alpha:]]{1}$/) && length(next_guess) < 5 do
        next_guess = next_guess ++ [{key, :try}]
        guesses = Enum.reverse([pad_guess(next_guess) | socket.assigns.game.guesses])
        grid = populate_grid(guesses)
        assign(socket, key: key, grid: grid, next_guess: next_guess)
      else
        socket
      end

    {:noreply, socket}
  end

  defp pad_guess(guess) do
    guess ++ List.duplicate({"", :empty}, 5 - length(guess))
  end

  defp empty_grid() do
    {"", :empty} |> List.duplicate(5) |> List.duplicate(6)
  end

  defp populate_grid(guesses) do
    empty_grid()
    |> Enum.with_index()
    |> Enum.map(fn {row, index} ->
      case Enum.fetch(guesses, index) do
        :error -> row
        {:ok, guess} -> guess
      end
    end)
  end
end
