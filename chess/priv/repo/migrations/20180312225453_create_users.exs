defmodule Chess.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string, null: false
      add :wins, :integer
      add :draws, :integer
      add :losses, :integer

      timestamps()
    end

  end
end
