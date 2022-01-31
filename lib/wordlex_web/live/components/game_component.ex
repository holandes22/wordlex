defmodule WordlexWeb.Components.Game do
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

  def guess_tile(assigns) do
    ~H"""
    <div id={"input-tile-#{@index}"} class="w-10 h-10 border-2 border-gray-300 bg-white text-gray-800 flex justify-center items-center md:w-16 md:h-16">
      <div class="text-xl uppercase text-gray-80 font-bold md:text-3xl"></div>
    </div>
    """
  end

  def tile(assigns) do
    classes =
      case assigns.state do
        :empty -> "border-2 border-gray-300"
        :correct -> "bg-green-500"
        :incorrect -> "bg-yellow-500"
        :invalid -> "bg-gray-500"
        _ -> "bg-white"
      end

    ~H"""
    <div class={"w-10 h-10 text-white #{classes} flex justify-center items-center md:w-16 md:h-16"}>
      <div class="text-xl uppercase font-bold md:text-3xl"><%= @char %></div>
    </div>
    """
  end

  def tile_grid(assigns) do
    ~H"""
    <div class="grid grid-rows-6 gap-1 place-content-evenly">
      <%= if @revealing? do %>
        <.tile_rows guesses={Enum.slice(@grid.past_guesses, 0..-2)} />
        <.tile_rows guesses={[List.last(@grid.past_guesses)]} animate_class="animate-flip" />
      <% else %>
        <.tile_rows guesses={@grid.past_guesses} />
      <% end %>

      <%= if not @game_over? do %>
        <div id="keyboard-input" phx-hook="KeyboardInput">
          <.tile_row animate_class={if(@valid_guess?, do: "", else: "animate-shake")} >
            <%= for index <- 0..4 do  %>
              <.guess_tile index={index} />
            <% end %>
          </.tile_row>
        </div>
      <% end  %>

      <.tile_rows guesses={@grid.remaining_guesses} />
    </div>
    """
  end

  defp tile_rows(assigns) do
    ~H"""
    <%= for guess <- @guesses do  %>
      <.tile_row animate_class={"#{assigns[:animate_class] || ""}"}>
        <%= for %{char: char, state: state} <- guess do  %>
          <.tile char={char} state={state} />
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
end
