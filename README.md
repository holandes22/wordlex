# Wordlex

Just another Wordle clone written in Elixir that uses Phoenix LiveView for the web app. Visit at [wordlex.fly.dev](https://wordlex.fly.dev/)

To start the server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# On the project

This was a fun weekend project to hack on. 
I used [LiveBook](https://livebook.dev/) to get the first pass of the game engine implemented which was a delightful experience.
The first draft of a working app was very fast to develop (Phoenix LiveView is just amazing), but had to scratch part of that to handle the
input client side as otherwise the latency when deployed was going to make it an awful experience (it was great for locahost, but wating 200/300 ms for each 
key press was not going to be nice). All in all took me about 8 hours from scratch to prod, which I think is great. 
