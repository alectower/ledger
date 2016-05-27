defmodule Ledger.SyncChannel do
  use Phoenix.Channel

  def join("sync", message, socket) do
    {:ok, socket}
  end

  def handle_in("sync_all", message, socket) do
    Ledger.Sync.start_link
    {:noreply, socket}
  end

  #def handle_out("update", message, socket) do
  #  IO.puts "Sending update"
  #  push socket, "update", message
  #  {:noreply, socket}
  #end
end
