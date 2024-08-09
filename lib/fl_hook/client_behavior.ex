defmodule FLHook.ClientBehavior do
  @moduledoc false

  alias FLHook.{Client, Command, Config}

  @callback start_link(Config.t() | [keyword | GenServer.option()]) ::
              GenServer.on_start()

  @callback start_link(Config.t(), GenServer.options()) :: GenServer.on_start()

  @callback close(Client.client(), timeout) :: :ok

  @callback connected?(Client.client(), timeout) :: boolean

  @callback event_mode?(Client.client(), timeout) :: boolean

  @callback cmd(Client.client(), Command.command(), timeout) ::
              {:ok, [binary]} | {:error, Exception.t()}

  @callback subscribe(Client.client(), pid, timeout) :: :ok

  @callback unsubscribe(Client.client(), pid, timeout) :: :ok
end
