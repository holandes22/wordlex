defmodule WordlexWeb.GameLive do
  use WordlexWeb, :live_view

  alias Wordlex.{GameEngine, WordServer}
  alias WordlexWeb.Components.Game

  def mount(_params, _session, socket) do
    word_to_guess = WordServer.word_to_guess()
    game = GameEngine.new(word_to_guess)

    game =
      game
      |> GameEngine.resolve("tugre")
      |> GameEngine.resolve("flock")
      |> GameEngine.resolve("aaaab")
      |> GameEngine.resolve("aaaab")
      |> GameEngine.resolve("aaaab")

    next_guess = []
    guesses = Enum.reverse([pad_guess(next_guess) | game.guesses])
    grid = populate_grid(guesses)
    {:ok, assign(socket, game: game, grid: grid, next_guess: next_guess)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-between h-screen" phx-window-keydown="key">
        <div class="flex flex-col items-center">
          <div class="w-screen border-b border-gray-300 md:w-96">
            <h1 class="p-2 text-center text-3xl text-gray-800 font-semibold uppercase tracking-widest">Wordlex</h1>
          </div>
          <p class="p-1 text-md text-gray-400 font-medium">A <a href="https://powerlanguage.co.uk/wordle" target="_blank" class="uppercase border-b border-gray-400">Wordle</a> clone written in elixir</p>
        </div>

        <%= if live_flash(@flash, :info) do %>
          <div phx-click="lv:clear-flash" phx-value-key="info">
            <Game.alert message={live_flash(@flash, :info)} />
          </div>
        <% end %>

        <div>
          <Game.tile_grid grid={@grid} />
          <%# TODO: remove word to guess %>
          <div class="text-center"><%= @game.word %></div>
        </div>

        <div class="mb-2">
          <Game.keyboard letter_map={GameEngine.letter_map(@game)} />
        </div>
    </div>
    """
  end

  def handle_event("key", _params, %{assigns: %{game: %{locked?: true}}} = socket) do
    {:noreply, socket}
  end

  def handle_event("key", %{"key" => "Backspace"}, socket) do
    {_element, next_guess} = List.pop_at(socket.assigns.next_guess, -1)
    guesses = Enum.reverse([pad_guess(next_guess) | socket.assigns.game.guesses])
    grid = populate_grid(guesses)
    {:noreply, assign(socket, next_guess: next_guess, grid: grid)}
  end

  def handle_event("key", %{"key" => "Enter"}, %{assigns: %{next_guess: guess}} = socket)
      when length(guess) < 5 do
    {:noreply, put_message(socket, "Not enough letters")}
  end

  def handle_event("key", %{"key" => "Enter"}, socket) do
    guess = tiles_to_string(socket.assigns.next_guess)
    game = GameEngine.resolve(socket.assigns.game, guess)
    next_guess = []
    guesses = Enum.reverse([pad_guess(next_guess) | game.guesses])
    grid = populate_grid(guesses)

    socket =
      if GameEngine.won?(game) do
        put_message(socket, "Success!")
      else
        socket
      end

    {:noreply, assign(socket, game: game, grid: grid, next_guess: next_guess)}
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

  def handle_info(:clear_message, socket), do: {:noreply, clear_flash(socket)}

  defp put_message(socket, message) do
    Process.send_after(self(), :clear_message, 2000)
    put_flash(socket, :info, message)
  end

  defp tiles_to_string(tiles) do
    tiles |> Enum.map(fn {char, _state} -> char end) |> Enum.join()
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
