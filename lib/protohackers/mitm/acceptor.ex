defmodule Protohackers.MITM.Acceptor do
  use Task, restart: :transient

  require Logger

  def start_link(opts) do
    Task.start_link(__MODULE__, :run, [Keyword.fetch!(opts, :port)])
  end

  def run(port) do
    case :gen_tcp.listen(port, [
           :binary,
           ifaddr: {0, 0, 0, 0},
           active: :once,
           packet: :line,
           reuseaddr: true
         ]) do
      {:ok, listen_socket} ->
        Logger.info("MITM server listening on port #{port}")
        accept_loop(listen_socket)

      {:error, reason} ->
        raise "failed to listen on port #{port}: #{inspect(reason)}"
    end
  end

  defp accept_loop(listen_socket) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, socket} ->
        {:ok, _} = Protohackers.MITM.ConnectionSupervisor.start_child(socket)
        accept_loop(listen_socket)

      {:error, reason} ->
        raise "failed to accept connection: #{inspect(reason)}"
    end
  end
end
