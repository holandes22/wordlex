defmodule WordlexWeb.GameLive do
  use WordlexWeb, :live_view
  import WordlexWeb.GameComponent
  alias Wordlex.{GameEngine, WordServer, Stats}

  @session_key "app:session"

  @impl true
  def(mount(_params, _session, socket)) do
    {game, stats} =
      case get_connect_params(socket) do
        # Socket not connected yet
        nil ->
          game = new_game()
          stats = Stats.new()
          {game, stats}

        %{"restore" => nil} ->
          game = new_game()
          stats = Stats.new()
          {game, stats}

        %{"restore" => data} ->
          game = game_from_json_string(data)
          stats = stats_from_json_string(data)
          {game, stats}
      end

    {:ok, assign(socket, game: game, stats: stats, revealing?: true, error_message: nil)}
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
            A <a href="https://www.nytimes.com/games/wordle/index.html" target="_blank" class="uppercase border-b border-gray-400">Wordle</a> clone written in elixir
          </p>
        </div>

        <%= if @error_message do %>
          <.alert message={@error_message} />
        <% end %>

        <div>
          <.grid
            past_guesses={Enum.reverse(@game.guesses)}
            valid_guess?={@error_message == nil}
            revealing?={length(@game.guesses) > 0 && @revealing?}
            game_over?={@game.over?}
          />
          <%# TODO: remove word to guess %>
          <div class="text-center"><%= @game.word %></div>
        </div>

        <.stats stats={@stats} />

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
    stats = update_stats(game, socket.assigns.stats)

    game =
      if game.over? do
        # TODO: reset game if game over and over midnight
        game
      else
        game
      end

    data = Jason.encode!(%{game: game, stats: stats})

    {:noreply,
     socket
     |> assign(game: game, stats: stats, revealing?: true)
     |> push_event("session:store", %{key: @session_key, data: data})
     |> push_event("keyboard:reset", %{})}
  end

  @impl true
  def handle_info(:clear_message, socket),
    do: {:noreply, assign(socket, error_message: nil)}

  defp put_message(socket, message) do
    Process.send_after(self(), :clear_message, 2000)
    assign(socket, error_message: message)
  end

  defp new_game(), do: WordServer.word_to_guess() |> GameEngine.new()

  defp update_stats(%{result: :playing}, stats), do: stats

  defp update_stats(%{result: :lost}, stats) do
    %{stats | lost: stats.lost + 1}
  end

  defp update_stats(game, stats) do
    key = abs(GameEngine.guesses_left(game) - 6)
    value = stats.guess_distribution[key] + 1
    %{stats | guess_distribution: Map.put(stats.guess_distribution, key, value)}
  end

  defp game_from_json_string(data) do
    %{game: game_data} = Jason.decode!(data, keys: :atoms)
    game = struct!(Wordlex.Game, game_data)

    result = String.to_existing_atom(game.result)

    guesses =
      Enum.map(game.guesses, fn guess ->
        Enum.map(guess, fn guess_info ->
          %{guess_info | state: String.to_existing_atom(guess_info.state)}
        end)
      end)

    %{game | result: result, guesses: guesses}
  end

  defp stats_from_json_string(data) do
    %{stats: stats_data} = Jason.decode!(data, keys: :atoms)
    struct!(Stats, stats_data)
  end
end
