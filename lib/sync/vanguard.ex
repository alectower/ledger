defmodule Ledger.Sync.Vanguard do
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
    Endpoint.broadcast! "sync", "update", %{log: "Vanguard: starting sync"}

    navigate_to "https://retirementplans.vanguard.com/VGApp/pe/PublicHome#/"

    sign_in

    answer_security_questions

    element = find_element :id, "continueInput"
    if element do
      click element
    end

    execute_script "remindMeLater();"

    :timer.sleep(2)

    Endpoint.broadcast! "sync", "update", %{log: "Vanguard: updating balance"}
    element = find_element :id, "sHomeContentForm:respSecureHomeTab:dcAggregatePlansBalanceValue"

    balance = visible_text element

    {balance, _} = balance
              |> String.replace_leading("$", "")
              |> String.replace(",", "")
              |> Float.parse

    balance = balance * 100 |> round

    model = Repo.get_by Account, name: "Vanguard"

    unless model do
     {:ok, model} = Repo.insert %Account{name: "Vanguard", type: 0, balance: 0}
    end

    model_changeset = Ecto.Changeset.change model, balance: balance
    {:ok, model} = Repo.update model_changeset

    Endpoint.broadcast! "sync", "balance_update", %{account_id: model.id, name: model.name, balance: model.balance, type: model.type}

    Endpoint.broadcast! "sync", "update", %{log: "Vanguard: done syncing!"}
    {:reply, :ok, state}
  end

  defp sign_in do
    Endpoint.broadcast! "sync", "update", %{log: "Vanguard: signing in"}
    element = find_element :id, "USER"
    fill_field element, Application.get_env(:ledger, :vanguard_username)

    element = find_element :id, "PASSWORD"
    fill_field element, Application.get_env(:ledger, :vanguard_password)

    element = find_element :css, "#LoginForm button[type=\"submit\"]"
    click element
  end

  defp answer_security_questions do
    Endpoint.broadcast! "sync", "update", %{log: "Vanguard: answering security questions"}
    element = find_element :css, "tr[tbodyid=\"LoginForm:summaryTabletbody0\"][index=\"1\"] td:last-child"
    question = visible_text element

    answer = cond do
      question =~ ~r/high school mascot/ -> Application.get_env(:ledger, :vanguard_a1)
      question =~ ~r/your first manager/ -> Application.get_env(:ledger, :vanguard_a2)
      question =~ ~r/grandfather's FIRST NAME/ -> Application.get_env(:ledger, :vanguard_a3)
      true ->
        IO.inspect question
        System.halt(0)
    end

    element = find_element :id, "LoginForm:ANSWER"
    fill_field element, answer

    element = find_element :id, "LoginForm:DEVICE:1"
    click element

    element = find_element :id, "LoginForm:ContinueInput"
    click element
  end
end
