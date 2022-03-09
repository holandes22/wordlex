defmodule WordlexWeb.GameLive do
  use WordlexWeb, :live_view
  import WordlexWeb.GameComponent
  alias Wordlex.{GameEngine, WordServer, Stats, Settings}

  @session_key "app:session"

  @impl true
  def mount(_params, _session, socket) do
    {game, stats, settings} =
      case get_connect_params(socket) do
        # Socket not connected yet
        nil ->
          game = new_game()
          stats = Stats.new()
          settings = Settings.new()
          {game, stats, settings}

        %{"restore" => nil} ->
          game = new_game()
          stats = Stats.new()
          settings = Settings.new()
          {game, stats, settings}

        %{"restore" => data} ->
          game = game_from_json_string(data)
          stats = stats_from_json_string(data)
          settings = settings_from_json_string(data)

          word_changed? =
            String.upcase(game.word) != WordServer.word_to_guess() |> String.upcase()

          game =
            if game.over? and word_changed? do
              new_game()
            else
              game
            end

          {game, stats, settings}
      end

    {:ok,
     assign(socket,
       game: game,
       stats: stats,
       revealing?: true,
       message: nil,
       valid_guess?: true,
       settings: settings,
       show_info_modal?: game.over?
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={"#{if(@settings.theme == :dark, do: "dark", else: "")}"}>
      <div id="game" phx-hook="Session" class="flex flex-col items-center justify-between h-screen dark:bg-gray-800">
          <div class="flex flex-col items-center">
            <div class="w-screen border-b border-gray-300 md:w-96">
              <div class="flex items-center justify-between">
                <button type="button">
                  <span class="sr-only">Show help</span>
                  <svg class="w-6 h-6 dark:text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                </button>

                <h1 class="p-2 text-center text-3xl text-gray-800 font-semibold uppercase tracking-widest dark:text-white">Wordlex</h1>

                <div>
                  <button type="button" phx-click={show_settings_modal()}>
                    <span class="sr-only">Show settings</span>
                    <svg class="w-6 h-6 dark:text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    </svg>
                  </button>
                  <button type="button" phx-click={show_info_modal()}>
                    <span class="sr-only">Show stats</span>
                    <svg class="w-6 h-6 dark:text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
                    </svg>
                  </button>
                </div>
              </div>
            </div>
            <p class="p-1 text-md text-gray-400 font-medium dark:text-gray-300">
              A <a href="https://www.nytimes.com/games/wordle/index.html" target="_blank" class="uppercase border-b border-gray-400">Wordle</a> clone written in elixir
            </p>
          </div>

          <%= if @message do %>
            <.alert message={@message} />
          <% end %>

          <div>
            <.grid
              past_guesses={Enum.reverse(@game.guesses)}
              valid_guess?={@valid_guess?}
              revealing?={length(@game.guesses) > 0 && @revealing?}
              game_over?={@game.over?}
            />
            <%# TODO: remove word to guess %>
            <div class="text-center"><%= @game.word %></div>
          </div>

          <.info_modal stats={@stats} show_countdown?={@game.over?} open?={@show_info_modal?} />
          <.settings_modal checked?={@settings.theme == :dark}/>


          <div class="mb-2">
            <.keyboard letter_map={GameEngine.letter_map(@game)} />
          </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_theme", _params, %{assigns: %{settings: settings}} = socket) do
    theme =
      case settings.theme do
        :dark -> :light
        :light -> :dark
      end

    settings = %{settings | theme: theme}
    {:noreply, socket |> assign(settings: settings) |> store_session()}
  end

  @impl true
  def handle_event("submit", _params, %{assigns: %{game: %{over?: true}}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"guess" => guess_string}, socket)
      when byte_size(guess_string) < 5 do
    {:noreply, put_message(socket, "Not enough letters") |> assign(valid_guess?: false)}
  end

  @impl true
  def handle_event("submit", %{"guess" => guess_string}, socket) do
    game = GameEngine.resolve(socket.assigns.game, guess_string)
    stats = update_stats(game, socket.assigns.stats)

    {:noreply,
     socket
     |> assign(game: game, stats: stats, revealing?: true, valid_guess?: true)
     |> maybe_put_game_over_message(game)
     |> maybe_show_info_dialog(game)
     |> store_session()
     |> push_event("keyboard:reset", %{})}
  end

  @impl true
  def handle_info(:clear_message, socket),
    do: {:noreply, assign(socket, message: nil, revealing?: false)}

  @impl true
  def handle_info(:show_info_modal, socket) do
    {:noreply, assign(socket, show_info_modal?: true)}
  end

  defp put_message(socket, message) do
    Process.send_after(self(), :clear_message, 2000)
    assign(socket, message: message)
  end

  defp maybe_show_info_dialog(socket, %{over?: false}) do
    socket
  end

  defp maybe_show_info_dialog(socket, %{over?: true}) do
    Process.send_after(self(), :show_info_modal, 2000)
    socket
  end

  defp maybe_put_game_over_message(socket, %{over?: false}), do: socket

  defp maybe_put_game_over_message(socket, %{result: :lost, word: word}),
    do: put_message(socket, "The solution was #{word}")

  defp maybe_put_game_over_message(socket, %{} = game) do
    message =
      case GameEngine.guesses_left(game) do
        0 -> "Phew!"
        1 -> "Nice!"
        2 -> "Superb!"
        3 -> "Impressive!"
        4 -> "Great!"
        _ -> "Outstanding!"
      end

    put_message(socket, message)
  end

  defp store_session(%{assigns: assigns} = socket) do
    data = assigns |> Map.take(~w(game stats settings)a) |> Jason.encode!()
    push_event(socket, "session:store", %{key: @session_key, data: data})
  end

  defp new_game(), do: WordServer.word_to_guess() |> GameEngine.new()

  defp update_stats(%{result: :playing}, stats), do: stats

  defp update_stats(%{result: :lost}, stats) do
    %{stats | lost: stats.lost + 1}
  end

  defp update_stats(game, stats) do
    key = abs(GameEngine.guesses_left(game) - 6) |> Integer.to_string()
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

    guess_distribution =
      Map.new(stats_data.guess_distribution, fn {k, v} -> {Atom.to_string(k), v} end)

    struct!(Stats, %{stats_data | guess_distribution: guess_distribution})
  end

  defp settings_from_json_string(data) do
    %{settings: settings_data} = Jason.decode!(data, keys: :atoms)
    settings = struct!(Settings, settings_data)
    %{settings | theme: String.to_existing_atom(settings.theme)}
  end
end
