defmodule Chess.Play do
  @moduledoc """
  The Play context.
  """

  import Ecto.Query, warn: false
  alias Chess.Repo

  alias Chess.Play.Game

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  def list_games do
    Repo.all(Game)
  end

  # List games with only one user where the user is not
  # the current user
  def list_open_games(id) do
    Repo.all(Game)
    |> Repo.preload(:white)
    |> Enum.filter(fn(x) ->
      x.black_id == nil &&
      x.white_id != id end)
  end

  # List games the user belongs to
  def list_my_games(id) do
    Repo.all(Game)
    |> Repo.preload(:white)
    |> Enum.filter(fn(x) ->
      x.white_id == String.to_integer(id) ||
      x.black_id == String.to_integer(id) end)
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(id) do
    Repo.get!(Game, id)
    |> Repo.preload(:white)
    |> Repo.preload(:black)
  end

  # def get_game_by_name(name) do
  #   game = Repo.all(Game)
  #   |> Enum.filter(fn(x) ->
  #     x.name == name end)
  # end

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Game.

  ## Examples

      iex> delete_game(game)
      {:ok, %Game{}}

      iex> delete_game(game)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{source: %Game{}}

  """
  def change_game(%Game{} = game) do
    Game.changeset(game, %{})
  end
end
