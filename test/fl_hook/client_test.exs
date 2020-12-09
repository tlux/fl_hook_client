defmodule FLHook.ClientTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Liveness
  import Mox

  alias FLHook.Client
  alias FLHook.Codec
  alias FLHook.Config
  alias FLHook.MockInetAdapter
  alias FLHook.MockTCPAdapter

  setup :set_mox_global

  setup do
    {:ok,
     config:
       Config.new(
         backoff_interval: 1234,
         codec: :unicode,
         connect_timeout: 2345,
         event_mode: false,
         handshake_recv_timeout: 3456,
         host: "foo.bar",
         inet_adapter: MockInetAdapter,
         password: "$3cret",
         port: 1920,
         send_timeout: 4567,
         subscribers: [self()],
         tcp_adapter: MockTCPAdapter
       )}
  end

  describe "start_link/1" do
    test "connect", %{config: config} do
      test_pid = self()
      fake_socket = make_ref()

      {:ok, pass_cmd} = Codec.encode(:unicode, "pass $3cret\r\n")

      MockTCPAdapter
      |> expect(:connect, fn 'foo.bar',
                             1920,
                             [:binary, active: false, send_timeout: 4567],
                             2345 ->
        {:ok, fake_socket}
      end)
      |> expect(:recv, fn ^fake_socket, 0, 3456 ->
        Codec.encode(:unicode, "Welcome to FLHack\r\n")
      end)
      |> expect(:send, fn ^fake_socket, ^pass_cmd ->
        :ok
      end)
      |> expect(:recv, fn ^fake_socket, 0, 3456 ->
        Codec.encode(:unicode, "OK\r\n")
      end)
      |> expect(:controlling_process, fn ^fake_socket, pid ->
        send(test_pid, {:controlling_process, pid})
        :ok
      end)

      expect(MockInetAdapter, :setopts, fn ^fake_socket, [active: :once] ->
        :ok
      end)

      client = start_supervised!({Client, config})

      assert eventually(fn -> verify!() end)
      assert :sys.get_state(client).mod_state.socket == fake_socket
    end

    test "connect with options keyword list" do
      test_pid = self()
      fake_socket = make_ref()

      {:ok, pass_cmd} = Codec.encode(:unicode, "pass $3cret\r\n")

      MockTCPAdapter
      |> expect(:connect, fn 'foo.bar',
                             1920,
                             [:binary, active: false, send_timeout: 4567],
                             2345 ->
        {:ok, fake_socket}
      end)
      |> expect(:recv, fn ^fake_socket, 0, 3456 ->
        Codec.encode(:unicode, "Welcome to FLHack\r\n")
      end)
      |> expect(:send, fn ^fake_socket, ^pass_cmd ->
        :ok
      end)
      |> expect(:recv, fn ^fake_socket, 0, 3456 ->
        Codec.encode(:unicode, "OK\r\n")
      end)
      |> expect(:controlling_process, fn ^fake_socket, pid ->
        send(test_pid, {:controlling_process, pid})
        :ok
      end)

      expect(MockInetAdapter, :setopts, fn ^fake_socket, [active: :once] ->
        :ok
      end)

      opts = [
        backoff_interval: 1234,
        codec: :unicode,
        connect_timeout: 2345,
        event_mode: false,
        handshake_recv_timeout: 3456,
        host: "foo.bar",
        inet_adapter: MockInetAdapter,
        name: FLHook.NamedTestClient,
        password: "$3cret",
        port: 1920,
        send_timeout: 4567,
        subscribers: [self()],
        tcp_adapter: MockTCPAdapter
      ]

      client = start_supervised!({Client, opts})

      assert eventually(fn -> verify!() end)

      client_state = :sys.get_state(client)

      assert client_state.mod_state.socket == fake_socket
      assert client_state == :sys.get_state(FLHook.NamedTestClient)
    end

    test "connect with event mode", %{config: config} do
      config = %{config | event_mode: true}

      test_pid = self()
      fake_socket = make_ref()

      {:ok, pass_cmd} = Codec.encode(:unicode, "pass $3cret\r\n")
      {:ok, eventmode_cmd} = Codec.encode(:unicode, "eventmode\r\n")

      MockTCPAdapter
      |> expect(:connect, fn 'foo.bar',
                             1920,
                             [:binary, active: false, send_timeout: 4567],
                             2345 ->
        {:ok, fake_socket}
      end)
      |> expect(:recv, fn ^fake_socket, 0, 3456 ->
        Codec.encode(:unicode, "Welcome to FLHack\r\n")
      end)
      |> expect(:send, fn ^fake_socket, ^pass_cmd ->
        :ok
      end)
      |> expect(:recv, fn ^fake_socket, 0, 3456 ->
        Codec.encode(:unicode, "OK\r\n")
      end)
      |> expect(:send, fn ^fake_socket, ^eventmode_cmd ->
        :ok
      end)
      |> expect(:recv, fn ^fake_socket, 0, 3456 ->
        Codec.encode(:unicode, "OK\r\n")
      end)
      |> expect(:controlling_process, fn ^fake_socket, pid ->
        send(test_pid, {:controlling_process, pid})
        :ok
      end)

      expect(MockInetAdapter, :setopts, fn ^fake_socket, [active: :once] ->
        :ok
      end)

      client = start_supervised!({Client, config})

      assert eventually(fn -> verify!() end)
      assert :sys.get_state(client).mod_state.socket == fake_socket
    end

    test "connect error", %{config: config} do
      config = %{config | backoff_interval: 200}

      expect(MockTCPAdapter, :connect, fn _, _, _, _ ->
        {:error, :econnrefused}
      end)

      assert capture_log(fn ->
               client = start_supervised!({Client, config})

               eventually(fn -> verify!() end)
               eventually(fn -> !Client.connected?(client) end)
             end) =~ "Socket error: connection refused"

      # should issue a reconnect after backoff interval elapsed
      expect(MockTCPAdapter, :connect, fn _, _, _, _ ->
        {:error, :econnrefused}
      end)

      assert capture_log(fn ->
               eventually(fn -> verify!() end)
             end)
    end

    test "handshake error", %{config: config} do
      fake_socket = make_ref()

      MockTCPAdapter
      |> expect(:connect, fn _, _, _, _ ->
        {:ok, fake_socket}
      end)
      |> expect(:recv, fn ^fake_socket, _, _ ->
        Codec.encode(:unicode, "Some invalid text\r\n")
      end)
      |> expect(:close, fn ^fake_socket ->
        :ok
      end)
      # should issue a reconnect
      |> expect(:connect, fn _, _, _, _ ->
        {:error, :econnrefused}
      end)

      capture_log(fn ->
        start_supervised!({Client, config})

        eventually(fn -> verify!() end)
      end) =~ "Socket is not a valid FLHook socket"
    end

    test "auth error", %{config: config} do
      fake_socket = make_ref()

      {:ok, pass_cmd} = Codec.encode(:unicode, "pass $3cret\r\n")

      MockTCPAdapter
      |> expect(:connect, fn _, _, _, _ ->
        {:ok, fake_socket}
      end)
      |> expect(:recv, fn ^fake_socket, _, _ ->
        Codec.encode(:unicode, "Welcome to FLHack\r\n")
      end)
      |> expect(:send, fn ^fake_socket, ^pass_cmd ->
        :ok
      end)
      |> expect(:recv, fn ^fake_socket, _, _ ->
        Codec.encode(:unicode, "ERR invalid password\r\n")
      end)
      |> expect(:close, fn ^fake_socket ->
        :ok
      end)
      # should issue a reconnect
      |> expect(:connect, fn _, _, _, _ ->
        {:error, :econnrefused}
      end)

      assert capture_log(fn ->
               start_supervised!({Client, config})

               eventually(fn -> verify!() end)
             end) =~ "Command error: invalid password"
    end

    test "event mode error", %{config: config} do
      config = %{config | event_mode: true}
      fake_socket = make_ref()

      {:ok, pass_cmd} = Codec.encode(:unicode, "pass $3cret\r\n")
      {:ok, eventmode_cmd} = Codec.encode(:unicode, "eventmode\r\n")

      MockTCPAdapter
      |> expect(:connect, fn _, _, _, _ ->
        {:ok, fake_socket}
      end)
      |> expect(:recv, fn ^fake_socket, _, _ ->
        Codec.encode(:unicode, "Welcome to FLHack\r\n")
      end)
      |> expect(:send, fn ^fake_socket, ^pass_cmd ->
        :ok
      end)
      |> expect(:recv, fn ^fake_socket, _, _ ->
        Codec.encode(:unicode, "OK\r\n")
      end)
      |> expect(:send, fn ^fake_socket, ^eventmode_cmd ->
        :ok
      end)
      |> expect(:recv, fn ^fake_socket, _, _ ->
        Codec.encode(:unicode, "ERR insufficient rights\r\n")
      end)
      |> expect(:close, fn ^fake_socket ->
        :ok
      end)
      # should issue a reconnect
      |> expect(:connect, fn _, _, _, _ ->
        {:error, :econnrefused}
      end)

      assert capture_log(fn ->
               start_supervised!({Client, config})

               eventually(fn -> verify!() end)
             end) =~ "Command error: insufficient rights"
    end
  end

  describe "connected?/1" do
    setup :verify_on_exit!

    test "connected", %{config: config} do
      fake_socket = make_ref()

      MockTCPAdapter
      |> expect(:connect, fn _, _, _, _ ->
        {:ok, fake_socket}
      end)
      |> expect(:recv, fn ^fake_socket, _, _ ->
        Codec.encode(:unicode, "Welcome to FLHack\r\n")
      end)
      |> expect(:send, fn ^fake_socket, _ ->
        :ok
      end)
      |> expect(:recv, fn ^fake_socket, _, _ ->
        Codec.encode(:unicode, "OK\r\n")
      end)
      |> expect(:controlling_process, fn ^fake_socket, _ ->
        :ok
      end)

      expect(MockInetAdapter, :setopts, fn ^fake_socket, _ ->
        :ok
      end)

      client = start_supervised!({Client, config})

      assert Client.connected?(client) == true
    end

    test "disconnected", %{config: config} do
      expect(MockTCPAdapter, :connect, fn _, _, _, _ ->
        {:error, :econnrefused}
      end)

      capture_log(fn ->
        client = start_supervised!({Client, config})

        assert Client.connected?(client) == false
      end)
    end
  end
end
