defmodule Ledger.Repo.Migrations.AddNameIndexToAccounts do
  use Ecto.Migration

  def change do
    create unique_index(:accounts, [:name, :type])
  end
end
