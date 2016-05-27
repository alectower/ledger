defmodule Ledger.Sync do
  alias Ledger.Sync.Bank

  def start_link do
    Task.start_link fn -> Bank.fetch_data end
  end
end
