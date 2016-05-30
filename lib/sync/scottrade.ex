defmodule Ledger.Sync.Scottrade do
  use GenServer
  use Hound.Helpers
  alias Ledger.Endpoint
  alias Ledger.Repo
  alias Ledger.Account

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def fetch_data do
    GenServer.call(__MODULE__, :fetch_data, 10000000)
  end

  def handle_call(:fetch_data, _from, state) do
    Hound.start_session
    Endpoint.broadcast! "sync", "update", %{log: "Scottrade: starting sync"}

    Endpoint.broadcast! "sync", "update", %{log: "Scottrade: signing in"}
    navigate_to "https://trading.scottrade.com"
    sign_in

    Endpoint.broadcast! "sync", "update", %{log: "Scottrade: updating balance"}
    update_balance

    Endpoint.broadcast! "sync", "update", %{log: "Scottrade: done syncing!"}
    {:reply, :ok, state}
  end

  defp sign_in do
    element = find_element :id, "ctl00_body_txtAccountNumber"
    fill_field element, Application.get_env(:ledger, :scottrade_username)

    element = find_element :id, "ctl00_body_txtPassword"
    fill_field element, Application.get_env(:ledger, :scottrade_password)

    element = find_element :id, "ctl00_body_btnLogin"
    click element
  end

  defp update_balance do
    element = find_element :css, "#ctl00_PageContent_ctl02_w1_widgetContent1_tblBalanceElements66 tr:last-child td:last-child"
    balance = visible_text element
    {balance, _} = balance
              |> String.replace_leading("$", "")
              |> String.replace(",", "")
              |> Float.parse
    balance = balance * 100 |> round

    model = Repo.get_by Account, name: "Scottrade"

    unless model do
     {:ok, model} = Repo.insert %Account{name: "Scottrade", type: 0, balance: 0}
    end

    model_changeset = Ecto.Changeset.change model, balance: balance
    {:ok, model} = Repo.update model_changeset

    Endpoint.broadcast! "sync", "balance_update", %{account_id: model.id, name: model.name, balance: model.balance, type: model.type}
  end
end
