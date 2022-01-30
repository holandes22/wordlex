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
    <div id={"input-tile-#{@index}"} class="w-10 h-10 border-2 bg-white text-gray-800 flex justify-center items-center md:w-16 md:h-16">
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
        <.tile_row animate_class={if(@valid_guess?, do: "", else: "animate-shake")} >
          <%= for index <- 0..4 do  %>
            <.guess_tile index={index} />
          <% end %>
        </.tile_row>
      <% end  %>

      <.tile_rows guesses={@grid.remaining_guesses} />
    </div>
    """
  end

  defp tile_rows(assigns) do
    ~H"""
    <%= for guess <- @guesses do  %>
      <.tile_row animate_class={"#{assigns[:animate_class] || ""}"}>
        <%= for {char, state} <- guess do  %>
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
    <div class="flex flex-col items-center space-y-1">
      <%= for line <- lines do %>
        <div class="flex items-center space-x-1">
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
        Enum.member?(letter_map.invalid, key) -> "bg-gray-500 hover:bg-gray-400"
        true -> "bg-gray-300 hover:bg-gray-200"
      end

    ~H"""
    <button
      phx-click={JS.dispatch("app:keyClicked", to: "#game", detail: %{ key: @key })}
      phx-click="key"
      phx-value-key={@key}
      class={"p-2 rounded #{classes} text-gray-800 text-md flex justify-center items-center uppercase md:p-4"}
    >
      <%= @key %>
    </button>
    """
  end
end
