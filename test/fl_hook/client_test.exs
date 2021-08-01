defmodule FLHook.ClientTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Liveness
  import Mox

  alias FLHook.Client
  alias FLHook.Codec
  alias FLHook.CodecError
  alias FLHook.CommandError
  alias FLHook.Config
  alias FLHook.MockInetAdapter
  alias FLHook.MockTCPAdapter
  alias FLHook.Result
  alias FLHook.SocketError

  setup :set_mox_global

  setup do
    {:ok,
     config:
       Config.new(
         backoff_interval: 1234,
         codec: :unicode,
         connect_timeout: 2345,
         event_mode: false,
         host: "foo.bar",
         inet_adapter: MockInetAdapter,
         password: "$3cret",
         port: 1920,
         recv_timeout: 3456,
         send_timeout: 4567,
         subscribers: [],
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
        host: "foo.bar",
        inet_adapter: MockInetAdapter,
        name: FLHook.NamedTestClient,
        password: "$3cret",
        port: 1920,
        recv_timeout: 3456,
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

  describe "cmd/1" do
    setup :stub_successful_connection

    setup %{config: config} do
      {:ok, client: start_supervised!({Client, config})}
    end

    test "successfully run string command", %{client: client, socket: socket} do
      {:ok, cmd} = Codec.encode(:unicode, "isloggedin Foobar\r\n")

      # Command sent
      expect(MockTCPAdapter, :send, fn ^socket, ^cmd ->
        :ok
      end)

      task =
        Task.async(fn ->
          Client.cmd(client, "isloggedin Foobar")
        end)

      assert eventually(fn -> command_queued?(client) end)

      # Result received
      expect(MockInetAdapter, :setopts, fn ^socket, [active: :once] ->
        :ok
      end)

      {:ok, msg} = Codec.encode(:unicode, "OK\r\n")
      send(client, {:tcp, socket, msg})

      assert {:ok, %Result{lines: []}} = Task.await(task)
    end

    test "successfully run tuple command", %{client: client, socket: socket} do
      {:ok, cmd} = Codec.encode(:unicode, "addcash Foobar 1234\r\n")

      # Command sent
      expect(MockTCPAdapter, :send, fn ^socket, ^cmd ->
        :ok
      end)

      task =
        Task.async(fn ->
          Client.cmd(client, {"addcash", ["Foobar", 1234]})
        end)

      assert eventually(fn -> command_queued?(client) end)

      # Result received
      expect(MockInetAdapter, :setopts, fn ^socket, [active: :once] ->
        :ok
      end)

      {:ok, msg} = Codec.encode(:unicode, "OK\r\n")
      send(client, {:tcp, socket, msg})

      assert {:ok, %Result{lines: []}} = Task.await(task)
    end

    test "command error", %{client: client, socket: socket} do
      {:ok, cmd} = Codec.encode(:unicode, "addcash Foobar 1234\r\n")

      # Command sent
      expect(MockTCPAdapter, :send, fn ^socket, ^cmd ->
        :ok
      end)

      task =
        Task.async(fn ->
          Client.cmd(client, "addcash Foobar 1234")
        end)

      assert eventually(fn -> command_queued?(client) end)

      # Result received
      expect(MockInetAdapter, :setopts, fn ^socket, [active: :once] ->
        :ok
      end)

      {:ok, msg} = Codec.encode(:unicode, "ERR player not logged in\r\n")
      send(client, {:tcp, socket, msg})

      assert Task.await(task) ==
               {:error, %CommandError{detail: "player not logged in"}}
    end

    test "connection closed error", %{client: client, socket: socket} do
      MockTCPAdapter
      |> expect(:close, fn ^socket ->
        :ok
      end)
      |> expect(:connect, fn _, _, _, _ ->
        {:error, :econnrefused}
      end)

      :ok = Client.close(client)

      capture_log(fn ->
        assert Client.cmd(client, "isloggedin Foobar") ==
                 {:error, %SocketError{reason: :closed}}
      end)
    end

    test "decode error", %{client: client, socket: socket} do
      {:ok, cmd} = Codec.encode(:unicode, "addcash Foobar 1234\r\n")

      # Command sent
      MockTCPAdapter
      |> expect(:send, fn ^socket, ^cmd -> :ok end)
      |> expect(:close, fn ^socket -> :ok end)
      |> expect(:connect, fn _, _, _, _ ->
        {:error, :econnrefused}
      end)

      expect(MockInetAdapter, :setopts, fn ^socket, [active: :once] ->
        :ok
      end)

      Process.flag(:trap_exit, true)

      capture_log(fn ->
        catch_exit do
          task =
            Task.async(fn ->
              Client.cmd(client, {"addcash", ["Foobar", 1234]})
            end)

          eventually(fn -> command_queued?(client) end)

          send(client, {:tcp, socket, "invalid"})

          Task.await(task)
        end

        assert_received {:EXIT, _,
                         {%CodecError{
                            codec: :unicode,
                            direction: :decode,
                            value: "invalid"
                          }, _}}
      end)
    end

    test "timeout error on receive", %{client: client, socket: socket} do
      {:ok, cmd} = Codec.encode(:unicode, "help\r\n")

      # Command sent
      expect(MockTCPAdapter, :send, fn ^socket, ^cmd -> :ok end)

      task =
        Task.async(fn ->
          Client.cmd(client, "help")
        end)

      assert eventually(fn -> command_queued?(client) end)

      # Result received
      expect(MockInetAdapter, :setopts, fn ^socket, [active: :once] ->
        :ok
      end)

      send(client, :timeout)

      assert {:error, %SocketError{reason: :timeout}} = Task.await(task)
    end
  end

  describe "cmd!/1" do
    setup :stub_successful_connection

    setup %{config: config} do
      {:ok, client: start_supervised!({Client, config})}
    end

    test "successfully run command"

    test "raise command error"

    test "raise connection closed error"
  end

  describe "subscribe/2" do
    setup :stub_successful_connection

    test "put subscription", %{config: config} do
      test_pid = self()
      client = start_supervised!({Client, config})

      assert :ok = Client.subscribe(client, test_pid)

      assert %{^test_pid => monitor_ref} =
               :sys.get_state(client).mod_state.subscriptions

      assert is_reference(monitor_ref)
    end

    test "do not overwrite existing subscription", %{config: config} do
      test_pid = self()
      client = start_supervised!({Client, config})

      assert :ok = Client.subscribe(client, test_pid)
      subscriptions = :sys.get_state(client).mod_state.subscriptions

      assert :ok = Client.subscribe(client, test_pid)
      assert :sys.get_state(client).mod_state.subscriptions == subscriptions
    end
  end

  describe "unsubscribe/2" do
    setup :stub_successful_connection

    test "remove subscription", %{config: config} do
      test_pid = self()
      config = %{config | subscribers: [test_pid]}

      client = start_supervised!({Client, config})

      assert %{^test_pid => _} = :sys.get_state(client).mod_state.subscriptions
      assert :ok = Client.unsubscribe(client, test_pid)
      assert :sys.get_state(client).mod_state.subscriptions == %{}
    end

    test "no-op when subscription not found", %{config: config} do
      test_pid = self()
      client = start_supervised!({Client, config})

      assert :sys.get_state(client).mod_state.subscriptions == %{}
      assert :ok = Client.unsubscribe(client, test_pid)
      assert :sys.get_state(client).mod_state.subscriptions == %{}
    end
  end

  describe "message loop" do
    setup :stub_successful_connection

    test "socket error", %{config: config, socket: socket} do
      expect(MockTCPAdapter, :close, fn ^socket -> :ok end)

      stub_successful_connection(config)

      assert capture_log(fn ->
               client = start_supervised!({Client, config})

               send(client, {:tcp_error, socket, :econnrefused})

               eventually(fn -> verify!() end)
             end) =~ "Socket error: connection refused"
    end

    test "closed error", %{config: config, socket: socket} do
      expect(MockTCPAdapter, :close, fn ^socket -> :ok end)

      stub_successful_connection(config)

      assert capture_log(fn ->
               client = start_supervised!({Client, config})

               send(client, {:tcp_closed, socket})

               eventually(fn -> verify!() end)
             end) =~ "Socket error: connection closed"
    end

    test "timeout error", %{config: config, socket: socket} do
      expect(MockTCPAdapter, :close, fn ^socket -> :ok end)

      stub_successful_connection(config)

      assert capture_log(fn ->
               client = start_supervised!({Client, config})

               send(client, {:tcp_error, socket, :timeout})

               eventually(fn -> verify!() end)
             end) =~ "Socket error: connection timed out"
    end

    test "subscriber exit", %{config: config} do
      {:ok, subscriber} =
        Task.start_link(fn ->
          Process.sleep(250)
        end)

      client =
        start_supervised!({Client, %{config | subscribers: [subscriber]}})

      assert %{^subscriber => monitor_ref} =
               :sys.get_state(client).mod_state.subscriptions

      assert is_reference(monitor_ref)

      assert eventually(fn ->
               map_size(:sys.get_state(client).mod_state.subscriptions) == 0
             end)

      verify!()
    end
  end

  describe "event handling" do
    setup :stub_successful_connection

    # test ""
  end

  defp stub_successful_connection(%{config: config}) do
    {:ok, socket: stub_successful_connection(config)}
  end

  defp stub_successful_connection(%Config{} = config) do
    socket = make_ref()

    MockTCPAdapter
    |> expect(:connect, fn _, _, _, _ ->
      {:ok, socket}
    end)
    |> expect(:recv, fn ^socket, _, _ ->
      Codec.encode(config.codec, "Welcome to FLHack\r\n")
    end)
    |> expect(:send, fn ^socket, _ ->
      :ok
    end)
    |> expect(:recv, fn ^socket, _, _ ->
      Codec.encode(config.codec, "OK\r\n")
    end)
    |> expect(:controlling_process, fn ^socket, _ ->
      :ok
    end)

    expect(MockInetAdapter, :setopts, fn ^socket, [active: :once] ->
      :ok
    end)

    socket
  end

  defp command_queued?(client) do
    :queue.len(:sys.get_state(client).mod_state.queue) > 0
  end
end
