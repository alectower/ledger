defmodule Ledger.PageController do
  use Ledger.Web, :controller
  alias Ledger.Account

  def index(conn, _params) do
    conn
    |> assign(:assets, Repo.all(from(a in Account, where: a.type == 0, order_by: [a.name])))
    |> assign(:liabilities, Repo.all(from(a in Account, where: a.type == 1, order_by: [a.name])))
    |> render "index.html"
  end
end
