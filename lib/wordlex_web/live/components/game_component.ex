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
    grid = empty_grid() |> populate_grid(assigns.guesses)

    ~H"""
    <div class="w-[22rem]">
      <div class="grid grid-cols-5 grid-rows-6 gap-2 place-content-evenly">
        <%= for guess <- grid do  %>
          <%= for {char, condition} <- guess do  %>
            <.tile char={char} condition={condition}/>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  def keyboard(assigns) do
    ~H"""
    """
  end

  defp empty_grid() do
    {"", :empty} |> List.duplicate(5) |> List.duplicate(6)
  end

  defp populate_grid(grid, guesses) do
    Enum.with_index(grid)
    |> Enum.map(fn {row, index} ->
      case Enum.fetch(guesses, index) do
        :error -> row
        {:ok, guess} -> guess
      end
    end)
  end
end
