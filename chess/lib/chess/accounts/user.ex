defmodule Chess.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset


  schema "users" do
    field :draws, :integer
    field :email, :string, null: false
    field :losses, :integer
    field :name, :string, null: false
    field :wins, :integer

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :wins, :draws, :losses])
    |> validate_required([:email, :name, :wins, :draws, :losses])
  end
end
