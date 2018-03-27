defmodule ChessWeb.PageController do
  use ChessWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  #Taken from Nat Tuck's lecture notes
  def feed(conn, _params) do
    changeset = Chess.Play.change_game(%Chess.Play.Game{})
    game = Map.get(changeset, :data)
    assigns = Map.get(conn, :assigns)
    current_user = Map.get(assigns, :current_user)
    user_id = Map.get(current_user, :id)
    new_white = %{ game | white_id: user_id, white: current_user }
    changeset = %{ changeset | data: new_white }

    games = Chess.Play.list_open_games(user_id)

    render conn, "feed.html", games: games, changeset: changeset
  end

  def my_games(conn, %{"id" => id}) do
    games = Chess.Play.list_my_games(id)
    changeset = Chess.Play.change_game(%Chess.Play.Game{})
    render conn, "my_games.html", games: games, changeset: changeset
  end
end
