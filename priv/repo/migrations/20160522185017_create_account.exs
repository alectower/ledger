defmodule Ledger.Repo.Migrations.CreateAccount do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :name, :string
      add :balance, :integer

      timestamps
    end

  end
end
