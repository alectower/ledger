defmodule Ledger.Sync.Bank do
  use Hound.Helpers
  alias Ledger.Endpoint
  alias Ledger.Repo
  alias Ledger.Account

  def fetch_data do
    Hound.start_session
    Endpoint.broadcast! "sync", "update", %{log: "Bank: starting sync"}

    navigate_to "https://www.fasecu.org/"
    sign_in

    update_balance %{name: "Checking", type: 0},
      %{account_link: "ContentBody_WebPartManager1_wp2038702031_wp1633176580_ShareAccounts_HyperLink1_1",
        balance_id: "ContentBody_history_lblAccountActualBalance"}

    element = find_element :css, "a[href=\"/fasecu/Landing.aspx\"]"
    click element

    update_balance %{name: "Savings", type: 0},
      %{account_link: "ContentBody_WebPartManager1_wp2038702031_wp1633176580_ShareAccounts_HyperLink1_0",
        balance_id: "ContentBody_history_lblAccountActualBalance"}

    element = find_element :css, "a[href=\"/fasecu/Landing.aspx\"]"
    click element

    update_balance %{name: "Car Loan", type: 1},
      %{account_link: "ContentBody_WebPartManager1_wp2038702031_wp1633176580_LoanAccounts_HyperLink1_0",
        balance_id: "ContentBody_history_lblLoanAccountBalance"}

    element = find_element :id, "LogOutHyperlink"
    click element

    Endpoint.broadcast! "sync", "update", %{log: "Bank: done syncing!"}
  end

  def sign_in do
    element = find_element :name, "RequestedLoginID"

    Endpoint.broadcast! "sync", "update", %{log: "Bank: authenticating"}
    fill_field element, Application.get_env(:ledger, :fasecu_username)
    submit_element element

    element = find_element :name, "ctl00$ContentBody$PassmarkLogin1$btnContinue"
    click element

    element = find_element :id, "ContentBody_PassmarkLogin1_Question"
    question = visible_text element

    answer = cond do
      question =~ ~r/mascot/ -> 'tiger'
      question =~ ~r/junior high school/ -> 'st johns'
      question =~ ~r/city was your high school/ -> 'fenton'
      true -> System.halt(0)
    end

    element = find_element :name, "ctl00$ContentBody$PassmarkLogin1$txtAnswer"
    fill_field element, answer

    element = find_element :name, "ctl00$ContentBody$PassmarkLogin1$btnContinueQuestion"
    click element

    element = find_element :name, "ctl00$ContentBody$PassmarkLogin1$Password"
    fill_field element, Application.get_env(:ledger, :fasecu_password)

    Endpoint.broadcast! "sync", "update", %{log: "Bank: signing in"}
    element = find_element :name, "ctl00$ContentBody$PassmarkLogin1$Login"
    click element
  end

  def update_balance(account, html) do
    Endpoint.broadcast! "sync", "update", %{log: "Bank: Updating #{account[:name]} balance"}
    element = find_element :id, html[:account_link]
    click element

    element = find_element :id, html[:balance_id]
    get_balance = fn (element) ->
      balance = visible_text element
      {balance, _} = balance
                |> String.replace_leading("$", "")
                |> String.replace(",", "")
                |> Float.parse
      balance * 100 |> round
    end
    balance = get_balance.(element)

    model = Repo.get_by Account, name: "FASECU - #{account[:name]}"
    unless model do
     {:ok, model} = Repo.insert %Account{name: "FASECU - #{account[:name]}", type: account[:type], balance: 0}
    end
    model_changeset = Ecto.Changeset.change model, balance: balance
    {:ok, model} = Repo.update model_changeset
    Endpoint.broadcast! "sync", "balance_update", %{account_id: model.id, name: model.name, balance: model.balance, type: model.type}
  end
end
