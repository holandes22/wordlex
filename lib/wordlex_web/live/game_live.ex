defmodule WordlexWeb.GameLive do
  use WordlexWeb, :live_view

  alias Wordlex.{GameEngine, WordServer}
  alias WordlexWeb.Components.Game

  def mount(_params, _session, socket) do
    word_to_guess = WordServer.word_to_guess()
    game = GameEngine.new(word_to_guess)
    game = game |> GameEngine.resolve("tugre") |> GameEngine.resolve("flock")
    {:ok, assign(socket, game: game)}
  end

  def render(assigns) do
    ~H"""
    <div><%= @game.word %></div>
    <Game.tile_grid guesses={@game.guessed_tiles} />
    """
  end
end
