defmodule Ledger.Sync do
  use Supervisor
  alias Ledger.Sync.Bank
  alias Ledger.Sync.TradeKing
  alias Ledger.Sync.Scottrade
  alias Ledger.Sync.Vanguard

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(arg) do
    children = [
      worker(Bank, []),
      worker(TradeKing, []),
      worker(Scottrade, []),
      worker(Vanguard, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def run do
   [
     &Bank.fetch_data/0,
     &TradeKing.fetch_data/0,
     &Scottrade.fetch_data/0,
     &Vanguard.fetch_data/0
   ]
   |> Enum.map(&(Task.async &1))
   |> Enum.map(&(Task.await &1, 10000000))
  end
end
