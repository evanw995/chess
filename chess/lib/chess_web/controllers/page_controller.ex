defmodule ChessWeb.PageController do
  use ChessWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  #Taken from Nat Tuck's lecture notes
  def feed(conn, _params) do
    games = Chess.Play.list_open_games()

    changeset = Chess.Play.change_game(%Chess.Play.Game{})
    game = Map.get(changeset, :data)
    assigns = Map.get(conn, :assigns)
    current_user = Map.get(assigns, :current_user)
    user_id = Map.get(current_user, :id)
    new_white = %{ game | white_id: user_id, white: current_user }
    changeset = %{ changeset | data: new_white }

    render conn, "feed.html", games: games, changeset: changeset
  end
end
