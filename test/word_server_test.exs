defmodule WordServerTest do
  use ExUnit.Case
  alias Wordlex.WordServer

  @words ["tuple", "crane", "claim"]
  @params [
    {~U[2022-01-01 00:00:00.00Z], "tuple"},
    {~U[2022-01-02 00:00:00.00Z], "crane"},
    {~U[2022-01-03 00:00:00.00Z], "claim"},
    {~U[2022-02-01 00:00:00.00Z], "crane"},
    {~U[2022-02-03 00:00:00.00Z], "tuple"}
  ]

  for {now, expected} <- @params do
    @now now
    @expected expected
    test "get_word_of_the_day returns #{expected} if date #{now}" do
      epoch_in_seconds = ~U[2022-01-01 00:00:00.00Z] |> DateTime.to_unix()
      now_in_seconds = DateTime.to_unix(@now)

      word =
        WordServer.get_word_of_the_day(@words,
          epoch_in_seconds: epoch_in_seconds,
          now_in_seconds: now_in_seconds
        )

      assert word == @expected
    end
  end
end
