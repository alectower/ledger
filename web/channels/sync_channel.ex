defmodule Ledger.SyncChannel do
  use Phoenix.Channel

  def join("sync", message, socket) do
    {:ok, socket}
  end

  def handle_in("sync_all", message, socket) do
    Ledger.Sync.run
    {:noreply, socket}
  end
end
