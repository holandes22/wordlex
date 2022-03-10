defmodule WordlexWeb.GameLive do
  use WordlexWeb, :live_view
  import WordlexWeb.GameComponent
  alias Wordlex.{GameEngine, WordServer, Stats, Settings, Game}

  @session_key "app:session"
  @session_version 1

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
          <.info_modal stats={@stats} show_countdown?={@game.over?} open?={@show_info_modal?} />
          <.settings_modal checked?={@settings.theme == :dark}/>
          <.header />

          <%= if @message do %>
            .alert message={@message} />
          <% end %>

          <div>
            <.grid
              past_guesses={Enum.reverse(@game.guesses)}
              valid_guess?={@valid_guess?}
              revealing?={length(@game.guesses) > 0 && @revealing?}
              game_over?={@game.over?}
            />
          </div>

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
  def handle_event("submit", _params, %{assigns: %{game: %Game{over?: true}}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"guess" => guess}, socket)
      when byte_size(guess) < 5 do
    {:noreply, socket |> put_message("Not enough letters") |> assign(valid_guess?: false)}
  end

  @impl true
  def handle_event("submit", %{"guess" => guess}, socket) do
    if WordServer.valid_guess?(guess) do
      game = GameEngine.resolve(socket.assigns.game, guess)
      stats = update_stats(game, socket.assigns.stats)

      {:noreply,
       socket
       |> assign(game: game, stats: stats, revealing?: true, valid_guess?: true)
       |> maybe_put_game_over_message(game)
       |> maybe_show_info_dialog(game)
       |> store_session()
       |> push_event("keyboard:reset", %{})}
    else
      {:noreply, socket |> put_message("Not in word list") |> assign(valid_guess?: false)}
    end
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
    data =
      assigns
      |> Map.take(~w(game stats settings)a)
      |> Map.put_new(:version, @session_version)
      |> Jason.encode!()

    push_event(socket, "session:store", %{key: @session_key, data: data})
  end

  defp new_game(), do: WordServer.word_to_guess() |> GameEngine.new()

  defp update_stats(%{result: :playing}, stats), do: stats

  defp update_stats(%{result: :lost}, stats) do
    %{stats | lost: stats.lost + 1}
  end

  defp update_stats(game, stats) do
    guessed_at_attempt = abs(GameEngine.guesses_left(game) - 6)
    key = Integer.to_string(guessed_at_attempt)
    value = stats.guess_distribution[key] + 1

    stats =
      if GameEngine.won?(game) do
        %{stats | guessed_at_attempt: guessed_at_attempt}
      else
        stats
      end

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
