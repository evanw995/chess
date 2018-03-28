defmodule Chess.Play.Game do
  use Ecto.Schema
  import Ecto.Changeset


  schema "games" do
    field :name, :string
    belongs_to :white, Chess.Accounts.User
    belongs_to :black, Chess.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :white_id, :black_id])
    |> validate_required([:name, :white_id])
  end
end
