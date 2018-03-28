defmodule ChessWeb.GamesChannel do
  use ChessWeb, :channel

  alias Chess.Game

  def join("games:" <> name, payload, socket) do
    if authorized?(payload) do
      game = Chess.GameBackup.load(name) || Game.newGame()
      # game = Game.newGame()
      socket = socket
      |> assign(:game, game)
      |> assign(:name, name)
      {:ok, %{"join" => name, "game" => Game.client_view(game)}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("move", %{ "oldLocation" => oldLocation, "newLocation" => newLocation }, socket) do
    game = Game.move(socket.assigns[:game], oldLocation, newLocation)
    Chess.GameBackup.save(socket.assigns[:name], game)
    socket = assign(socket, :game, game)
    {:reply, {:ok, %{ "game" => Game.client_view(game)}}, socket}
  end

  # Unused
  # def handle_in("checkmate", %{ "turn" => turn }, socket) do
  #   raise socket
  # end

  # def handle_in("stalemate", %{}, socket) do
  #   assigns = Map.get(socket, :assigns)
  #   game_name = Map.get(assigns, :name)
  #   game = Chess.Play.get_game_by_name(game_name)
  #          |> Enum.at(0)
  #   {:reply, {:ok, %{ "id" => game.id }}, socket}
  # end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
