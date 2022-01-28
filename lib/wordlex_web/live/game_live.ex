defmodule WordlexWeb.GameLive do
  use WordlexWeb, :live_view

  alias Wordlex.{GameEngine, WordServer}
  alias WordlexWeb.Components.Game

  @type tile_state() :: :empty | :try | :correct | :incorrect | :invalid
  @type tile() :: {String.t(), tile_state()}
  @type guess() :: list(tile())
  @type grid() :: %{
          past_guesses: list(guess()),
          next_guess: guess() | nil,
          remaining_guesses: list(guess())
        }

  def(mount(_params, _session, socket)) do
    word_to_guess = WordServer.word_to_guess()
    game = GameEngine.new(word_to_guess)

    game =
      game
      |> GameEngine.resolve("tugre")
      |> GameEngine.resolve("flock")
      |> GameEngine.resolve("aaaab")
      |> GameEngine.resolve("aaaab")
      |> GameEngine.resolve("aaaab")

    {:ok, assign_state(socket, game, "")}
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

        <%= @valid_guess? %>

        <div>
          <Game.tile_grid grid={@grid} valid?={@valid_guess?}/>
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
    guess_string = String.slice(socket.assigns.guess_string, 0..-2)
    {:noreply, assign_state(socket, socket.assigns.game, guess_string)}
  end

  def handle_event("key", %{"key" => "Enter"}, %{assigns: %{guess_string: guess}} = socket)
      when byte_size(guess) < 5 do
    {:noreply, assign(socket, valid_guess?: false) |> put_message("Not enough letters")}
  end

  def handle_event("key", %{"key" => "Enter"}, socket) do
    game = GameEngine.resolve(socket.assigns.game, socket.assigns.guess_string)

    socket =
      if GameEngine.won?(game) do
        put_message(socket, "Success!")
      else
        socket
      end

    {:noreply, assign_state(socket, game, "")}
  end

  def handle_event("key", %{"key" => key}, socket) do
    guess_string = socket.assigns.guess_string

    socket =
      if String.match?(key, ~r/^[[:alpha:]]{1}$/) && byte_size(guess_string) < 5 do
        guess_string = guess_string <> key
        assign_state(socket, socket.assigns.game, guess_string)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info(:clear_message, socket),
    do: {:noreply, assign(socket, valid_guess?: true) |> clear_flash()}

  defp assign_state(socket, game, guess_string, valid_guess? \\ true) do
    grid =
      if game.locked? do
        populate_grid(Enum.reverse(game.guesses), nil)
      else
        populate_grid(Enum.reverse(game.guesses), string_to_guess(guess_string))
      end

    assign(socket, game: game, guess_string: guess_string, grid: grid, valid_guess?: valid_guess?)
  end

  defp put_message(socket, message) do
    Process.send_after(self(), :clear_message, 2000)
    put_flash(socket, :info, message)
  end

  @spec string_to_guess(String.t()) :: guess()
  defp string_to_guess(guess_string) do
    guess = guess_string |> String.graphemes() |> Enum.map(fn char -> {char, :try} end)
    guess ++ List.duplicate({"", :empty}, 5 - length(guess))
  end

  @spec empty_guess() :: guess()
  defp empty_guess(), do: {"", :empty} |> List.duplicate(5)

  @spec empty_guesses(Integer.t()) :: list(guess())
  defp empty_guesses(amount), do: List.duplicate(empty_guess(), amount)

  @spec populate_grid(list(guess), guess() | nil) :: grid()
  defp populate_grid(past_guesses, guess) do
    amount = max(6 - length(past_guesses) - 1, 0)
    remaining_guesses = empty_guesses(amount)
    %{past_guesses: past_guesses, next_guess: guess, remaining_guesses: remaining_guesses}
  end
end
