defmodule Ledger.Sync do
  use Supervisor
  alias Ledger.Sync.Bank
  alias Ledger.Sync.TradeKing

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(arg) do
    children = [
      worker(Bank, []),
      worker(TradeKing, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def run do
    bank = Task.async &Bank.fetch_data/0
    trade = Task.async &TradeKing.fetch_data/0
    Task.await(bank, 10000000)
    Task.await(trade, 10000000)
  end
end
