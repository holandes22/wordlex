defmodule WordlexWeb.Components.Game do
  use WordlexWeb, :component

  def tile(assigns) do
    border_classes =
      case assigns.condition do
        :empty -> "border-2 border-gray-400"
        :try -> "border-2 border-gray-800"
        _ -> ""
      end

    bg_color =
      case assigns.condition do
        :correct -> "bg-green-500"
        :incorrect -> "bg-yellow-500"
        :invalid -> "bg-gray-500"
        _ -> "bg-white"
      end

    text_color =
      case assigns.condition do
        :try -> "text-gray-800"
        _ -> "text-white"
      end

    ~H"""
    <div class={"p-2 w-16 h-16  #{bg_color} #{border_classes} flex justify-center items-center"}>
      <div class={"uppercase #{text_color} font-bold text-3xl"}><%= @char %></div>
    </div>
    """
  end

  def tile_grid(assigns) do
    ~H"""
    <div class="w-[22rem]">
      <div class="grid grid-cols-5 grid-rows-6 gap-2 place-content-evenly">
        <%= for guess <- @grid do  %>
          <%= for {char, condition} <- guess do  %>
            <.tile char={char} condition={condition}/>
          <% end %>
        <% end %>
      </div>
    </div>
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
        <.keyboard_line letters={line} />
      <% end %>
    </div>
    """
  end

  defp keyboard_line(assigns) do
    ~H"""
    <div class="flex items-center space-x-1">
      <%= for letter <- @letters do %>
        <button class="p-4 rounded bg-gray-300 text-gray-900 text-xl flex justify-center items-center uppercase" phx-click="key" phx-value-key={letter}>
          <%= letter %>
        </button>
      <% end %>
    </div>
    """
  end
end
