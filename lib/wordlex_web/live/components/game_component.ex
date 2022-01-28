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

  def tile(assigns) do
    border_classes =
      case assigns.state do
        :empty -> "border-2 border-gray-300"
        :try -> "border-2 border-gray-500"
        _ -> ""
      end

    bg_color =
      case assigns.state do
        :correct -> "bg-green-500"
        :incorrect -> "bg-yellow-500"
        :invalid -> "bg-gray-500"
        _ -> "bg-white"
      end

    text_color =
      case assigns.state do
        :try -> "text-gray-800"
        _ -> "text-white"
      end

    ~H"""
    <div class={"w-10 h-10 #{bg_color} #{border_classes} flex justify-center items-center md:w-16 md:h-16"}>
      <div class={"text-xl uppercase #{text_color} font-bold md:text-3xl"}><%= @char %></div>
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
        <.tile_rows guesses={@grid.past_guesses} valid?={true} />
      <% end %>

      <%= if @grid.next_guess do %>
        <.tile_rows guesses={[@grid.next_guess]} animate_class={if(@valid_guess?, do: "", else: "animate-shake")} />
      <% end %>

      <.tile_rows guesses={@grid.remaining_guesses} />
    </div>
    """
  end

  defp tile_rows(assigns) do
    ~H"""
    <%= for guess <- @guesses do  %>
      <div class={"grid grid-cols-5 gap-1 place-content-evenly #{assigns[:animate_class] || ""}"}>
        <%= for {char, state} <- guess do  %>
          <.tile char={char} state={state} />
        <% end %>
      </div>
    <% end %>
    """
  end

  def keyboard(assigns) do
    lines =
      [
        "Q W E R T Y U I O P",
        "A S D F G H J K L",
        "Enter Z X C V B N M Backspace"
      ]
      |> Enum.map(&String.split/1)

    ~H"""
    <div class="flex flex-col items-center space-y-1">
      <%= for line <- lines do %>
        <div class="flex items-center space-x-1">
          <%= for letter <- line do %>
            <%= cond do  %>
              <% Enum.member?(@letter_map.correct, letter) ->  %>
                <.button bg_class={"bg-green-500 hover:bg-green-400"} letter={letter} />
              <% Enum.member?(@letter_map.incorrect, letter) ->  %>
                <.button bg_class={"bg-yellow-500 hover:bg-yellow-400"} letter={letter} />
              <% Enum.member?(@letter_map.invalid, letter) ->  %>
                <.button bg_class={"bg-gray-500 hover:bg-gray-400"} letter={letter} />
              <% true ->  %>
                <.button bg_class={"bg-gray-300 hover:bg-gray-200"} letter={letter} />
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp button(assigns) do
    ~H"""
    <button class={"p-2 rounded #{@bg_class} text-gray-800 text-md flex justify-center items-center uppercase md:p-4"} phx-click="key" phx-value-key={@letter}>
      <%= @letter %>
    </button>
    """
  end
end
