defmodule ChessWeb.GameController do
  use ChessWeb, :controller

  alias Chess.Play
  alias Chess.Play.Game

  def index(conn, _params) do
    games = Play.list_games()
    render(conn, "index.html", games: games)
  end

  def new(conn, _params) do
    changeset = Play.change_game(%Game{})
    game = Map.get(changeset, :data)
    assigns = Map.get(conn, :assigns)
    current_user = Map.get(assigns, :current_user)
    user_id = Map.get(current_user, :id)
    new_white = %{ game | white_id: user_id, white: current_user }
    changeset = %{ changeset | data: new_white }
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"game" => game_params}) do
    case Play.create_game(game_params) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Game created successfully.")
        |> redirect(to: game_path(conn, :show, game))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    game = Play.get_game!(id)
    black_player = Map.get(game, :black)
    black_name =
      case black_player do
        nil -> ""
        _ -> Map.get(black_player, :name)
      end
    white_player = Map.get(game, :white)
    white_name = Map.get(white_player, :name)
    render(conn, "show.html", game: game, white: white_name, black: black_name)
  end

  def edit(conn, %{"id" => id}) do
    game = Play.get_game!(id)
    changeset = Play.change_game(game)
    render(conn, "edit.html", game: game, changeset: changeset)
  end

  def update(conn, %{"id" => id, "game" => game_params}) do
    game = Play.get_game!(id)

    case Play.update_game(game, game_params) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Game updated successfully.")
        |> redirect(to: game_path(conn, :show, game))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", game: game, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    game = Play.get_game!(id)
    {:ok, _game} = Play.delete_game(game)

    conn
    |> put_flash(:info, "Game deleted successfully.")
    |> redirect(to: game_path(conn, :index))
  end
end
