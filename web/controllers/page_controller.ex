defmodule Ledger.PageController do
  use Ledger.Web, :controller
  alias Ledger.Account

  def index(conn, _params) do
    conn
    |> assign(:assets, accounts(:assets))
    |> assign(:liabilities, accounts(:liabilities))
    |> render("index.html")
  end

  defp accounts(:assets), do: accounts(0)
  defp accounts(:liabilities), do: accounts(1)
  defp accounts(type) do
    Repo.all(
      from(
        a in Account,
        where: a.type == ^type,
        order_by: [a.name]
      )
    )
  end
end
