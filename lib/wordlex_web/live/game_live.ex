defmodule WordlexWeb.GameLive do
  use WordlexWeb, :live_view

  alias Wordlex.{GameEngine, WordServer}
  alias WordlexWeb.Components.Game

  @type tile_state() :: :empty | :correct | :incorrect | :invalid
  @type tile() :: {String.t(), tile_state()}
  @type guess() :: list(tile())
  @type grid() :: %{
          past_guesses: list(guess()),
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

    {:ok, assign_state(socket, game) |> assign(revealing?: false)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-between h-screen">
        <div class="flex flex-col items-center">
          <div class="w-screen border-b border-gray-300 md:w-96">
            <h1 class="p-2 text-center text-3xl text-gray-800 font-semibold uppercase tracking-widest">Wordlex</h1>
          </div>
          <p class="p-1 text-md text-gray-400 font-medium">A <a href="https://powerlanguage.co.uk/wordle" target="_blank" class="uppercase border-b border-gray-400">Wordle</a> clone written in elixir</p>
        </div>

        <%= if @error_message do %>
          <Game.alert message={@error_message} />
        <% end %>

        <%= if GameEngine.won?(@game) do %>
          <span>WINNER!</span>
        <% end %>

        <%= if GameEngine.guesses_left(@game) == 0 do %>
          <span>No more guesses!</span>
        <% end %>

        <div>
          <Game.tile_grid
            grid={@grid}
            valid_guess?={@error_message == nil}
            revealing?={length(@grid.past_guesses) > 0 && @revealing?}
            game_over?={@game.over?}
          />
          <%# TODO: remove word to guess %>
          <div class="text-center"><%= @game.word %></div>
        </div>

        <div class="mb-2">
          <Game.keyboard letter_map={GameEngine.letter_map(@game)} />
        </div>
    </div>
    """
  end

  def handle_event("submit", _params, %{assigns: %{game: %{over?: true}}} = socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"guess" => guess_string}, socket)
      when byte_size(guess_string) < 5 do
    {:noreply, put_message(socket, "Not enough letters") |> assign(revealing?: false)}
  end

  def handle_event("submit", %{"guess" => guess_string}, socket) do
    game = GameEngine.resolve(socket.assigns.game, guess_string)

    {:noreply,
     assign_state(socket, game)
     |> assign(revealing?: true)
     |> Phoenix.LiveView.push_event("app:resetGuess", %{})}
  end

  def handle_info(:clear_message, socket),
    do: {:noreply, assign(socket, error_message: nil)}

  defp assign_state(socket, game, error_message \\ nil) do
    grid = populate_grid(Enum.reverse(game.guesses))

    assign(socket,
      game: game,
      grid: grid,
      error_message: error_message
    )
  end

  defp put_message(socket, message) do
    Process.send_after(self(), :clear_message, 2000)
    assign(socket, error_message: message)
  end

  @spec empty_guess(Integer.t()) :: guess()
  defp empty_guess(tile_count \\ 5), do: List.duplicate({"", :empty}, tile_count)

  @spec empty_guesses(Integer.t()) :: list(guess())
  defp empty_guesses(guess_count), do: List.duplicate(empty_guess(), guess_count)

  @spec populate_grid(list(guess)) :: grid()
  defp populate_grid(past_guesses) do
    # need to account for the guess input line, so we remove an extra one
    guess_count = max(6 - length(past_guesses) - 1, 0)
    remaining_guesses = empty_guesses(guess_count)
    %{past_guesses: past_guesses, remaining_guesses: remaining_guesses}
  end
end
