defmodule WordlexWeb.GameComponent do
  use WordlexWeb, :component

  def header(assigns) do
    ~H"""
    <div class="flex flex-col items-center">
      <div class="pr-2 pl-2 w-screen border-b border-gray-300 md:w-96 md:pr-0 md:pl-0">
        <div class="flex items-center justify-between">
          <button type="button">
            <span class="sr-only">Show help</span>
            <svg class="w-6 h-6 dark:text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
          </button>

          <h1 class="p-2 text-center text-xl text-gray-800 font-semibold uppercase tracking-widest dark:text-white md:text-3xl">Wordlex</h1>

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
      <p class="p-1 text-sm text-gray-400 font-medium dark:text-gray-300 md:text-md">
        A <a href="https://www.nytimes.com/games/wordle/index.html" target="_blank" class="uppercase border-b border-gray-400">Wordle</a> clone written in elixir
      </p>
    </div>
    """
  end

  def alert(assigns) do
    ~H"""
    <div class="rounded bg-gray-800 p-4 dark:bg-gray-50">
      <div class="flex items-center justify-center">
        <p class="text-white text-xl dark:text-gray-800"><%= @message %></p>
      </div>
    </div>
    """
  end

  def grid(assigns) do
    offsset =
      if assigns.game_over? do
        0
      else
        1
      end

    count = max(6 - length(assigns.past_guesses) - offsset, 0)
    empty_tiles = List.duplicate(%{char: "", state: :empty}, 5) |> List.duplicate(count)

    ~H"""
    <div class="grid grid-rows-6 gap-1 place-content-evenly">
      <%= if @revealing? do %>
        <.tile_rows guesses={Enum.slice(@past_guesses, 0..-2)} />
        <.tile_rows guesses={[List.last(@past_guesses)]} animate_class="animate-flip" />
      <% else %>
        <.tile_rows guesses={@past_guesses} />
      <% end %>

      <%= if not @game_over? do %>
        <div id="keyboard-input" phx-hook="KeyboardInput">
          <.tile_row animate_class={if(@valid_guess?, do: "", else: "animate-shake")} >
            <%= for index <- 0..4 do  %>
              <.input_guess_tile index={index} />
            <% end %>
          </.tile_row>
        </div>
      <% end  %>

      <.tile_rows guesses={empty_tiles} />
    </div>
    """
  end

  defp tile_rows(assigns) do
    ~H"""
    <%= for guess <- @guesses do  %>
      <.tile_row animate_class={"#{assigns[:animate_class] || ""}"}>
        <%= for %{char: char, state: state} <- guess do  %>
          <.guess_tile char={char} state={state} />
        <% end %>
      </.tile_row>
    <% end %>
    """
  end

  defp tile_row(assigns) do
    ~H"""
    <div class={"grid grid-cols-5 gap-1 place-content-evenly #{@animate_class}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def tile(assigns) do
    ~H"""
    <div id={@id} class={"w-14 h-14 flex justify-center items-center #{@extra_classes} sm:w-16 sm:h-16"}>
      <div class="text-3xl uppercase font-bold"><%= @char %></div>
    </div>
    """
  end

  def guess_tile(assigns) do
    extra_classes =
      case assigns.state do
        :empty ->
          empty_tile_classes()

        :correct ->
          "text-white bg-green-500"

        :incorrect ->
          "text-white bg-yellow-500"

        :invalid ->
          "text-white bg-gray-500"
      end

    ~H"""
    <.tile char={@char} id={nil} extra_classes={extra_classes} />
    """
  end

  def input_guess_tile(assigns) do
    ~H"""
    <.tile char="" id={"input-tile-#{@index}"} extra_classes={empty_tile_classes()} />
    """
  end

  def keyboard(assigns) do
    lines = [
      ~w(Q W E R T Y U I O P),
      ~w(A S D F G H J K L),
      ~w(Enter Z X C V B N M Backspace)
    ]

    ~H"""
    <div class="flex flex-col items-center space-y-1 md:space-y-2">
      <%= for line <- lines do %>
        <div class="flex items-center space-x-1 md:space-x-2">
          <%= for key <- line do %>
            <.key letter_map={@letter_map} key={key} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp empty_tile_classes do
    "bg-white text-gray-800 border-2 border-gray-300 dark:bg-gray-800 dark:border-gray-500 dark:text-white"
  end

  defp key(%{letter_map: letter_map, key: key} = assigns) do
    classes =
      cond do
        Enum.member?(letter_map.correct, key) -> "bg-green-500 hover:bg-green-400"
        Enum.member?(letter_map.incorrect, key) -> "bg-yellow-500 hover:bg-yellow-400"
        Enum.member?(letter_map.invalid, key) -> "bg-gray-400 hover:bg-gray-300"
        true -> "bg-gray-300 hover:bg-gray-200"
      end

    body =
      case key do
        "Backspace" ->
          ~H"""
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2M3 12l6.414 6.414a2 2 0 001.414.586H19a2 2 0 002-2V7a2 2 0 00-2-2h-8.172a2 2 0 00-1.414.586L3 12z"></path>
          </svg>
          """

        _ ->
          ~H"""
          <%= @key %>
          """
      end

    size_classes =
      case key do
        "Backspace" -> "h-10 w-8 sm:w-16 sm:h-12"
        "Enter" -> "h-10 w-18 sm:h-12"
        _ -> "h-10 w-8 sm:w-10 sm:h-12"
      end

    ~H"""
    <button
      phx-click={JS.dispatch("keyboard:clicked", to: "#keyboard-input", detail: %{ key: @key })}
      class={"#{size_classes} #{classes} p-2 rounded text-gray-700 text-md flex font-bold justify-center items-center uppercase focus:ring-2"}
    >
      <%= body %>
    </button>
    """
  end

  def show_info_modal() do
    show_modal("info-modal")
  end

  def hide_info_modal() do
    hide_modal("info-modal")
  end

  def show_settings_modal() do
    show_modal("settings-modal")
  end

  def hide_settings_modal() do
    hide_modal("settings-modal")
  end

  def show_modal(id) do
    JS.show(%JS{},
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"},
      to: "##{id}"
    )
  end

  def hide_modal(id) do
    JS.hide(%JS{},
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"},
      to: "##{id}"
    )
  end

  def modal(assigns) do
    class =
      if Map.get(assigns, :open?, false) do
        "fixed z-10 inset-0 overflow-y-auto"
      else
        "fixed z-10 inset-0 overflow-y-auto hidden"
      end

    ~H"""
    <div id={@modal_id} class={class} aria-labelledby="modal-title" role="dialog" aria-modal="true">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true"></div>
        <!-- This element is to trick the browser into centering the modal contents. -->
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
        <div class="mb-24 w-full inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:p-6 dark:bg-gray-800">
          <div class="absolute top-0 right-0 pt-4 pr-4">
            <button type="button" phx-click={hide_modal(@modal_id)} class="bg-white rounded-md text-gray-600 hover:text-gray-800 dark:bg-gray-800 dark:text-white dark:hover:text-gray-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              <span class="sr-only">Close</span>
              <!-- Heroicon name: outline/x -->
              <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          <div class="mt-8"><%= render_slot(@inner_block) %></div>
        </div>
      </div>
    </div>
    """
  end

  def info_modal(assigns) do
    won_count =
      Enum.reduce(assigns.stats.guess_distribution, 0, fn {_, value}, acc -> acc + value end)

    played = won_count + assigns.stats.lost
    show_guess_dist? = played > 0
    win_percent = floor(won_count / max(played, 1) * 100)

    ~H"""
    <.modal modal_id="info-modal" open?={@open?}>
      <div class="flex flex-col items-center space-y-4">
        <h2 class="text-gray-800 text-lg font-semibold uppercase dark:text-white">Statistics</h2>
        <div class="flex items-center space-x-4">
          <.stat value={played} label="Played" />
          <.stat value={win_percent} label="Win %" />
          <.stat value="N/A" label="Current Streak" />
          <.stat value="N/A" label="Max Streak" />
        </div>
        <h2 class="mt-2 text-gray-800 text-lg font-semibold uppercase dark:text-white">Guess distribution</h2>
        <%= if show_guess_dist? do %>
          <.guess_distribution stats={@stats}/>
        <% else %>
          <pre class="text-gray-700 text-sm dark:text-white">No Data</pre>
        <% end %>
        <%= if @show_countdown? do %>
        <h2 class="mt-2 text-gray-800 text-lg font-semibold uppercase dark:text-white">Next word in</h2>
          <.countdown />
        <% end %>
      </div>
    </.modal>
    """
  end

  def settings_modal(assigns) do
    ~H"""
    <.modal modal_id="settings-modal">
      <div class="space-y-4">
        <div class="pb-4 flex justify-between border-b border-gray-200 dark:border-gray-400">
          <p class="text-md text-gray-800 font-semibold dark:text-white">Enable Dark Theme</p>
          <button phx-click="toggle_theme" type="button" class={"#{if(@checked?, do: "bg-green-600", else: "bg-gray-200")} relative inline-flex flex-shrink-0 h-6 w-11 border-2 border-transparent rounded-full cursor-pointer transition-colors ease-in-out duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"} role="switch" aria-checked="false">
            <span class="sr-only">Toggle theme</span>
            <span aria-hidden="true" class={"#{if(@checked?, do: "translate-x-5", else: "translate-x-0")} pointer-events-none inline-block h-5 w-5 rounded-full bg-white shadow transform ring-0 transition ease-in-out duration-200"}></span>
          </button>
        </div>
        <div class="pb-4 flex justify-between border-b border-gray-200 dark:border-gray-400">
          <p class="text-md text-gray-800 font-semibold dark:text-white">Source Code</p>
          <a href="https://github.com/holandes22/wordlex" target="_blank" class="text-gray-400 border-b border-gray-400 dark:text-gray-300 dark:border-gray-300">wordlex</a>
        </div>
      </div>
    </.modal>
    """
  end

  def stat(assigns) do
    ~H"""
    <div class="flex flex-col items-center space-y-2">
      <div class="text-gray-800 text-3xl font-semibold dark:text-white"><%= @value %></div>
      <pre class="text-gray-700 text-xs break-words dark:text-gray-200"><%= @label %></pre>
    </div>
    """
  end

  def guess_distribution(assigns) do
    ~H"""
    <div class="space-y-1">
      <%= for {key, value} <- @stats.guess_distribution do %>
        <div class="flex flex-row items-center justify-start space-x-2 font-mono">
          <div class="text-sm text-gray-700 dark:text-white"><%= key %></div>
          <div class={"#{stat_bg_class(@stats, key)} font-semibold text-white text-medium text-right #{dist_bar_width(value)}"}><div class="ml-1 mr-1"><%= value %></div></div>
        </div>
      <% end %>
    </div>
    """
  end

  def countdown(assigns) do
    ~H"""
    <div id="countdown" phx-hook="Countdown" class="h-8 font-mono dark:text-white"></div>
    """
  end

  defp stat_bg_class(%{guessed_at_attempt: guessed_at_attempt}, key) do
    if guessed_at_attempt != nil and Integer.to_string(guessed_at_attempt) == key do
      "bg-green-600"
    else
      "bg-gray-500"
    end
  end

  defp dist_bar_width(0), do: "w-[1rem]"
  defp dist_bar_width(1), do: "w-[1rem]"
  defp dist_bar_width(2), do: "w-[2rem]"
  defp dist_bar_width(3), do: "w-[3rem]"
  defp dist_bar_width(4), do: "w-[4rem]"
  defp dist_bar_width(5), do: "w-[5rem]"
  defp dist_bar_width(6), do: "w-[6rem]"
  defp dist_bar_width(7), do: "w-[7rem]"
  defp dist_bar_width(8), do: "w-[8rem]"
  defp dist_bar_width(9), do: "w-[9rem]"
  defp dist_bar_width(10), do: "w-[10rem]"
  defp dist_bar_width(11), do: "w-[11rem]"
  defp dist_bar_width(12), do: "w-[12rem]"
  defp dist_bar_width(13), do: "w-[13rem]"
  defp dist_bar_width(14), do: "w-[14rem]"
  defp dist_bar_width(15), do: "w-[15rem]"
  defp dist_bar_width(_key), do: "w-full"
end
