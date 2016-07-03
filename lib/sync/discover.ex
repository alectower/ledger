defmodule Ledger.Sync.Discover do
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
    Endpoint.broadcast! "sync", "update", %{log: "Discover: starting sync"}

    Endpoint.broadcast! "sync", "update", %{log: "Discover: signing in"}

    navigate_to "https://www.discover.com/"

    sign_in

    Endpoint.broadcast! "sync", "update", %{log: "Discover: updating balance"}
    update_balance

    Endpoint.broadcast! "sync", "update", %{log: "Discover: done syncing!"}
    {:reply, :ok, state}
  end

  defp sign_in do
    element = find_element :id, "userid-content"
    fill_field element, Application.get_env(:ledger, :discover_username)

    element = find_element :id, "password-content"
    fill_field element, Application.get_env(:ledger, :discover_password)

    element = find_element :id, "login-form-content"
    submit_element element
  end

  defp update_balance do
    element = find_element :css, ".card-details .card-balances > ul:first-child li:nth-child(2)"
    balance = visible_text element
    {balance, _} = balance
              |> String.replace_leading("$", "")
              |> String.replace(",", "")
              |> Float.parse
    balance = balance * 100 |> round

    model = Repo.get_by Account, name: "Discover"

    unless model do
     {:ok, model} = Repo.insert %Account{name: "Discover", type: 1, balance: 0}
    end

    model_changeset = Ecto.Changeset.change model, balance: balance
    {:ok, model} = Repo.update model_changeset

    Endpoint.broadcast! "sync", "balance_update", %{account_id: model.id, name: model.name, balance: model.balance, type: model.type}
  end
end
