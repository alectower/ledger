defmodule Ledger.Repo.Migrations.AddTypeToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :type, :integer
    end
  end
end
