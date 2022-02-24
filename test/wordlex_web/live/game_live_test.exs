defmodule WordlexWeb.GameLiveTest do
  use WordlexWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias Wordlex.{GameEngine, Stats}

  setup %{conn: conn} do
    {:ok, game: GameEngine.new("sugar"), conn: conn}
  end

  test "initial render", %{conn: conn} do
    {:ok, _view, html} = conn |> put_connect_params(%{"restore" => nil}) |> live("/")
    assert html =~ "Wordlex"
  end

  test "winning renders a message", %{conn: conn, game: game} do
    {:ok, view, _html} = conn |> put_session(game) |> live("/")

    assert view
           |> element("#keyboard-input")
           |> render_hook("submit", %{guess: "sugar"}) =~ "Outstanding!"
  end

  test "loosing renders a message", %{conn: conn, game: game} do
    game =
      "wrong"
      |> List.duplicate(5)
      |> Enum.reduce(game, fn guess, game ->
        GameEngine.resolve(game, guess)
      end)

    {:ok, view, _html} = conn |> put_session(game) |> live("/")

    assert view
           |> element("#keyboard-input")
           |> render_hook("submit", %{guess: "wrong"}) =~ "The solution was #{game.word}"
  end

  test "short guess renders a message", %{conn: conn, game: game} do
    {:ok, view, _html} = conn |> put_session(game) |> live("/")

    assert view
           |> element("#keyboard-input")
           |> render_hook("submit", %{guess: "bad"}) =~ "Not enough letters"
  end

  defp put_session(socket, game, stats \\ Stats.new()) do
    data = Jason.encode!(%{game: game, stats: stats})
    put_connect_params(socket, %{"restore" => data})
  end
end
