defmodule WordlexWeb.GameComponent do
  use WordlexWeb, :component

  def alert(assigns) do
    ~H"""
    <div class="rounded bg-gray-900 p-4">
      <div class="flex items-center justify-center">
        <p class="text-white text-xl"><%= @message %></p>
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
    <div id={@id} class={"w-10 h-10 flex justify-center items-center md:w-16 md:h-16 #{@extra_classes}"}>
      <div class="text-xl uppercase font-bold md:text-3xl"><%= @char %></div>
    </div>
    """
  end

  def guess_tile(assigns) do
    extra_classes =
      case assigns.state do
        :empty -> "bg-white text-gray-800 border-2 border-gray-300"
        :correct -> "text-white bg-green-500"
        :incorrect -> "text-white bg-yellow-500"
        :invalid -> "text-white bg-gray-500"
      end

    ~H"""
    <.tile char={@char} id={nil} extra_classes={extra_classes} />
    """
  end

  def input_guess_tile(assigns) do
    ~H"""
    <.tile char="" id={"input-tile-#{@index}"} extra_classes="bg-white text-gray-800 border-2 border-gray-300" />
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
        "Backspace" -> "h-10 w-16 md:w-18 md:h-12"
        "Enter" -> "h-10 w-16 md:w-18 md:h-12"
        _ -> "h-10 w-8 md:w-10 md:h-12"
      end

    ~H"""
    <button
      phx-click={JS.dispatch("keyboard:clicked", to: "#keyboard-input", detail: %{ key: @key })}
      class={"#{size_classes} #{classes} p-2 rounded text-gray-700 text-sm flex font-bold justify-center items-center uppercase focus:ring-2"}
    >
      <%= body %>
    </button>
    """
  end

  def show_info_modal(js \\ %JS{}) do
    JS.show(js,
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"},
      to: "#info-modal"
    )
  end

  def hide_info_modal(js \\ %JS{}) do
    JS.hide(js,
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"},
      to: "#info-modal"
    )
  end

  def info_modal(assigns) do
    won_count =
      Enum.reduce(assigns.stats.guess_distribution, 0, fn {_, value}, acc -> acc + value end)

    played = won_count + assigns.stats.lost
    win_percent = floor(won_count / max(played, 1) * 100)

    ~H"""
    <div id="info-modal" class="fixed z-10 inset-0 overflow-y-auto hidden" aria-labelledby="modal-title" role="dialog" aria-modal="true">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true"></div>
        <!-- This element is to trick the browser into centering the modal contents. -->
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
        <div class="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
          <div class="hidden sm:block absolute top-0 right-0 pt-4 pr-4">
            <button type="button" phx-click={hide_info_modal()} class="bg-white rounded-md text-gray-600 hover:text-gray-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              <span class="sr-only">Close</span>
              <!-- Heroicon name: outline/x -->
              <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          <div class="flex flex-col items-center space-y-4">
            <h2 class="text-gray-800 text-lg font-semibold uppercase">Statistics</h2>
            <div class="flex items-center space-x-4">
              <.stat value={played} label="Played" />
              <.stat value={win_percent} label="Win %" />
              <.stat value="N/A" label="Current Streak" />
              <.stat value="N/A" label="Max Streak" />
            </div>
            <h2 class="mt-2 text-gray-800 text-lg font-semibold uppercase">Guess distribution</h2>
            <%= if played == 0 do %>
              <pre class="text-gray-700 text-sm">No Data</pre>
            <% else %>
              <.guess_distribution dist_map={@stats.guess_distribution} />
            <% end %>
            <.countdown countdown={@countdown} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  def stat(assigns) do
    ~H"""
    <div class="flex flex-col items-center space-y-2">
      <div class="text-gray-800 text-3xl font-semibold"><%= @value %></div>
      <pre class="text-gray-700 text-xs break-words"><%= @label %></pre>
    </div>
    """
  end

  def guess_distribution(assigns) do
    ~H"""
    <div class="space-y-1">
      <%= for {key, value} <- @dist_map do %>
        <div class="flex flex-row items-center justify-start space-x-2">
          <div class="text-sm text-gray-700"><%= key %></div>
          <div class={"bg-gray-500 font-semibold text-white text-medium text-right #{dist_bar_width(value)}"}><div class="ml-1 mr-1"><%= value %></div></div>
        </div>
      <% end %>
    </div>
    """
  end

  def countdown(assigns) do
    ~H"""
    <div><%= @countdown %></div>
    """
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
