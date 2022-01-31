defmodule WordlexWeb.GameLive do
  use WordlexWeb, :live_view
  import WordlexWeb.Components.Game
  alias Wordlex.{GameEngine, WordServer}

  @session_key "app:session"

  @impl true
  def(mount(_params, _session, socket)) do
    game =
      case get_connect_params(socket) do
        # Socket not connected yet
        nil ->
          WordServer.word_to_guess() |> GameEngine.new()

        %{"restore" => nil} ->
          WordServer.word_to_guess() |> GameEngine.new()

        %{"restore" => data} ->
          game_from_json_string(data)
      end

    {:ok, socket |> assign_game_and_grid(game) |> assign(revealing?: true, error_message: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="game" phx-hook="Session" class="flex flex-col items-center justify-between h-screen">
        <div class="flex flex-col items-center">
          <div class="w-screen border-b border-gray-300 md:w-96">
            <h1 class="p-2 text-center text-3xl text-gray-800 font-semibold uppercase tracking-widest">Wordlex</h1>
          </div>
          <p class="p-1 text-md text-gray-400 font-medium">
            A <a href="https://powerlanguage.co.uk/wordle" target="_blank" class="uppercase border-b border-gray-400">Wordle</a> clone written in elixir
          </p>
        </div>

        <%= if @error_message do %>
          <.alert message={@error_message} />
        <% end %>

        <div>
          <.tile_grid
            grid={@grid}
            valid_guess?={@error_message == nil}
            revealing?={length(@grid.past_guesses) > 0 && @revealing?}
            game_over?={@game.over?}
          />
          <%# TODO: remove word to guess %>
          <div class="text-center"><%= @game.word %></div>
        </div>

        <div class="mb-2">
          <.keyboard letter_map={GameEngine.letter_map(@game)} />
        </div>
    </div>
    """
  end

  @impl true
  def handle_event("submit", _params, %{assigns: %{game: %{over?: true}}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"guess" => guess_string}, socket)
      when byte_size(guess_string) < 5 do
    {:noreply, put_message(socket, "Not enough letters") |> assign(revealing?: false)}
  end

  @impl true
  def handle_event("submit", %{"guess" => guess_string}, socket) do
    game = GameEngine.resolve(socket.assigns.game, guess_string)

    socket =
      if game.over? do
        push_event(socket, "session:clear", %{key: @session_key})
      else
        push_event(socket, "session:store", %{key: @session_key, data: Jason.encode!(game)})
      end

    {:noreply,
     socket
     |> assign_game_and_grid(game)
     |> assign(revealing?: true)
     |> push_event("keyboard:reset", %{})}
  end

  @impl true
  def handle_info(:clear_message, socket),
    do: {:noreply, assign(socket, error_message: nil)}

  defp assign_game_and_grid(socket, game) do
    past_guesses = Enum.reverse(game.guesses)
    guess_count = max(6 - length(past_guesses) - 1, 0)

    remaining_guesses =
      List.duplicate(%{char: "", state: :empty}, 5) |> List.duplicate(guess_count)

    grid = %{past_guesses: past_guesses, remaining_guesses: remaining_guesses}

    assign(socket, game: game, grid: grid)
  end

  defp put_message(socket, message) do
    Process.send_after(self(), :clear_message, 2000)
    assign(socket, error_message: message)
  end

  defp game_from_json_string(data) do
    game = struct!(Wordlex.Game, Jason.decode!(data, keys: :atoms))
    result = String.to_existing_atom(game.result)

    guesses =
      Enum.map(game.guesses, fn guess ->
        Enum.map(guess, fn guess_info ->
          %{guess_info | state: String.to_existing_atom(guess_info.state)}
        end)
      end)

    %{game | result: result, guesses: guesses}
  end
end
