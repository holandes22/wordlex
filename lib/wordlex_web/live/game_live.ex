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
    <div
        id="game"
        phx-hook="AlpineDispatch"
        x-data={"{
          guess: '',
          onKeyClicked( key ) {
            if (key === 'Enter') {
              this.onEnterPressed()
            } else if (key === 'Backspace') {
              this.onBackspacePressed()
            } else {
              this.onCharPressed( key )
            }
          },
          onCharPressed( char ) {
            if(this.guess.length < 5) {
              this.guess = this.guess + char
            }

          },
          onBackspacePressed() {
            this.guess = this.guess.slice(0, -1)
          },
          onEnterPressed() {
            $dispatch('alpine:event', { event: 'submit', payload: { guess: this.guess } })
          }
        }"}
        class="flex flex-col items-center justify-between h-screen"
    >
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
          <Game.tile_grid grid={@grid} valid_guess?={@error_message == nil} revealing?={length(@grid.past_guesses) > 0}  locked?={@game.locked?} />
          <%# TODO: remove word to guess %>
          <div class="text-center"><%= @game.word %></div>
        </div>

        <div class="mb-2">
          <Game.keyboard letter_map={GameEngine.letter_map(@game)} />
        </div>
    </div>
    """
  end

  def handle_event("submit", _params, %{assigns: %{game: %{locked?: true}}} = socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"guess" => guess_string}, socket)
      when byte_size(guess_string) < 5 do
    {:noreply, put_message(socket, "Not enough letters")}
  end

  def handle_event("submit", %{"guess" => guess_string}, socket) do
    game = GameEngine.resolve(socket.assigns.game, guess_string)
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
    do: {:noreply, assign(socket, error_message: nil)}

  defp assign_state(socket, game, guess_string, error_message \\ nil) do
    grid =
      if game.locked? do
        populate_grid(Enum.reverse(game.guesses), nil)
      else
        populate_grid(Enum.reverse(game.guesses), string_to_guess(guess_string))
      end

    assign(socket,
      game: game,
      guess_string: guess_string,
      grid: grid,
      error_message: error_message
    )
  end

  defp put_message(socket, message) do
    Process.send_after(self(), :clear_message, 2000)
    assign(socket, error_message: message)
  end

  @spec string_to_guess(String.t()) :: guess()
  defp string_to_guess(guess_string) do
    guess = guess_string |> String.graphemes() |> Enum.map(fn char -> {char, :try} end)
    # Pad with empty tiles if needed
    guess ++ empty_guess(5 - length(guess))
  end

  @spec empty_guess(Integer.t()) :: guess()
  defp empty_guess(tile_count \\ 5), do: List.duplicate({"", :empty}, tile_count)

  @spec empty_guesses(Integer.t()) :: list(guess())
  defp empty_guesses(guess_count), do: List.duplicate(empty_guess(), guess_count)

  @spec populate_grid(list(guess), guess() | nil) :: grid()
  defp populate_grid(past_guesses, guess) do
    guess_count = max(6 - length(past_guesses) - 1, 0)
    remaining_guesses = empty_guesses(guess_count)
    %{past_guesses: past_guesses, next_guess: guess, remaining_guesses: remaining_guesses}
  end
end
