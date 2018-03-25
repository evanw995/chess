defmodule Chess.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :name, :string, null: false
      add :white_id, references(:users, on_delete: :delete_all), null: false
      add :black_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:games, [:white_id])
    create index(:games, [:black_id])
  end
end
