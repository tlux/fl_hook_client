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
  alias FLHook.Event
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
         tcp_adapter: MockTCPAdapter
       )}
  end

  describe "start_link/1" do
    test "connect", %{config: config} do
      test_pid = self()
      fake_socket = make_ref()

      {:ok, pass_cmd} = Codec.encode(:unicode, "pass $3cret\r\n")

      MockTCPAdapter
      |> expect(:connect, fn ~c"foo.bar",
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

      expect_socket_set_to_active_once(fake_socket)

      client = start_supervised!({Client, config})

      eventually(fn -> verify!() end)

      assert :sys.get_state(client).mod_state.socket == fake_socket
    end

    test "connect with options keyword list" do
      test_pid = self()
      fake_socket = make_ref()

      {:ok, pass_cmd} = Codec.encode(:unicode, "pass $3cret\r\n")

      MockTCPAdapter
      |> expect(:connect, fn ~c"foo.bar",
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

      expect_socket_set_to_active_once(fake_socket)

      client =
        start_supervised!(
          {Client,
           [
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
             tcp_adapter: MockTCPAdapter
           ]}
        )

      eventually(fn -> verify!() end)

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
      |> expect(:connect, fn ~c"foo.bar",
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

      expect_socket_set_to_active_once(fake_socket)

      client = start_supervised!({Client, config})

      eventually(fn -> verify!() end)

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

      capture_log(fn ->
        eventually(fn -> verify!() end)
      end)
    end

    test "unexpected string on handshake", %{config: config} do
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

      assert capture_log(fn ->
               start_supervised!({Client, config})

               eventually(fn -> verify!() end)
             end) =~ "Socket is not a valid FLHook socket"
    end

    test "handshake error", %{config: config} do
      fake_socket = make_ref()

      MockTCPAdapter
      |> expect(:connect, fn _, _, _, _ ->
        {:ok, fake_socket}
      end)
      |> expect(:recv, fn ^fake_socket, _, _ ->
        {:error, :econnreset}
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
             end) =~ Exception.message(%SocketError{reason: :econnreset})
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

  describe "open/1" do
    setup :verify_on_exit!

    setup %{config: config} do
      {:ok, config: %{config | connect_on_start: false}}
    end

    test "connect", %{config: config} do
      test_pid = self()
      fake_socket = make_ref()

      {:ok, pass_cmd} = Codec.encode(:unicode, "pass $3cret\r\n")

      MockTCPAdapter
      |> expect(:connect, fn ~c"foo.bar",
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

      expect_socket_set_to_active_once(fake_socket)

      client = start_supervised!({Client, config})

      assert Client.open(client) == :ok

      assert :sys.get_state(client).mod_state.socket == fake_socket
    end

    test "connect error", %{config: config} do
      expect(MockTCPAdapter, :connect, fn _, _, _, _ ->
        {:error, :econnrefused}
      end)

      client = start_supervised!({Client, config})

      assert Client.open(client) ==
               {:error, %SocketError{reason: :econnrefused}}
    end

    test "handshake error", %{config: config} do
      fake_socket = make_ref()

      MockTCPAdapter
      |> expect(:connect, fn _, _, _, _ ->
        {:ok, fake_socket}
      end)
      |> expect(:recv, fn ^fake_socket, _, _ ->
        {:error, :econnreset}
      end)
      |> expect(:close, fn ^fake_socket -> :ok end)

      client = start_supervised!({Client, config})

      assert Client.open(client) == {:error, %SocketError{reason: :econnreset}}
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

      expect_socket_set_to_active_once(fake_socket)

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

  describe "cmd/2" do
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

      eventually(fn -> command_queued?(client) end)

      # Result received
      expect_socket_set_to_active_once(socket)

      send_unicode_tcp_message(client, socket, "OK\r\n")

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
      expect_socket_set_to_active_once(socket)

      send_unicode_tcp_message(client, socket, "OK\r\n")

      assert {:ok, %Result{lines: []}} = Task.await(task)
    end

    test "successfully run command with result",
         %{client: client, socket: socket} do
      {:ok, cmd} = Codec.encode(:unicode, "help\r\n")

      # Command sent
      expect(MockTCPAdapter, :send, fn ^socket, ^cmd ->
        :ok
      end)

      task =
        Task.async(fn ->
          Client.cmd(client, "help")
        end)

      eventually(fn -> command_queued?(client) end)

      # Result received
      expect_socket_set_to_active_once(socket, 3)

      send_unicode_tcp_message(client, socket, "Line 1\r\n")
      send_unicode_tcp_message(client, socket, "Line 2\r\n")
      send_unicode_tcp_message(client, socket, "OK\r\n")

      assert {:ok, %Result{lines: ["Line 1", "Line 2"]}} = Task.await(task)
    end

    test "send error", %{client: client, socket: socket} do
      {:ok, cmd} = Codec.encode(:unicode, "addcash Foobar 1234\r\n")

      expect(MockTCPAdapter, :send, fn ^socket, ^cmd ->
        {:error, :something_went_wrong}
      end)

      assert Client.cmd(client, "addcash Foobar 1234") ==
               {:error, %SocketError{reason: :something_went_wrong}}
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
      expect_socket_set_to_active_once(socket)

      send_unicode_tcp_message(
        client,
        socket,
        "ERR player not logged in\r\n"
      )

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

      expect_socket_set_to_active_once(socket)

      Process.flag(:trap_exit, true)

      capture_log(fn ->
        cought_exit =
          catch_exit do
            task =
              Task.async(fn ->
                Client.cmd(client, {"addcash", ["Foobar", 1234]})
              end)

            eventually(fn -> command_queued?(client) end)

            send_tcp_message(client, socket, "invalid")

            Task.await(task)
          end

        assert {{%CodecError{
                   codec: :unicode,
                   direction: :decode,
                   value: "invalid"
                 }, _}, _} = cought_exit
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
      expect_socket_set_to_active_once(socket)

      send(client, :timeout)

      assert {:error, %SocketError{reason: :timeout}} = Task.await(task)
    end
  end

  describe "cmd!/2" do
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
          Client.cmd!(client, "isloggedin Foobar")
        end)

      eventually(fn -> command_queued?(client) end)

      # Result received
      expect_socket_set_to_active_once(socket)

      send_unicode_tcp_message(client, socket, "OK\r\n")

      assert %Result{lines: []} = Task.await(task)
    end

    test "successfully run tuple command", %{client: client, socket: socket} do
      {:ok, cmd} = Codec.encode(:unicode, "addcash Foobar 1234\r\n")

      # Command sent
      expect(MockTCPAdapter, :send, fn ^socket, ^cmd ->
        :ok
      end)

      task =
        Task.async(fn ->
          Client.cmd!(client, {"addcash", ["Foobar", 1234]})
        end)

      assert eventually(fn -> command_queued?(client) end)

      # Result received
      expect_socket_set_to_active_once(socket)

      send_unicode_tcp_message(client, socket, "OK\r\n")

      assert %Result{lines: []} = Task.await(task)
    end

    test "raise command error", %{client: client, socket: socket} do
      {:ok, cmd} = Codec.encode(:unicode, "addcash Foobar 1234\r\n")

      # Command sent
      expect(MockTCPAdapter, :send, fn ^socket, ^cmd ->
        :ok
      end)

      test_pid = self()

      task =
        Task.async(fn ->
          try do
            Client.cmd!(client, "addcash Foobar 1234")
          rescue
            e -> send(test_pid, e)
          end
        end)

      assert eventually(fn -> command_queued?(client) end)

      # Result received
      expect_socket_set_to_active_once(socket)

      send_unicode_tcp_message(
        client,
        socket,
        "ERR player not logged in\r\n"
      )

      Task.await(task)

      assert_received %CommandError{detail: "player not logged in"}
    end
  end

  describe "subscribe/2" do
    setup :stub_successful_connection

    test "put subscription", %{config: config} do
      test_pid = self()
      client = start_supervised!({Client, config})

      assert :ok = Client.subscribe(client, test_pid)

      assert %{^test_pid => monitor_ref} =
               :sys.get_state(client).mod_state.listeners

      assert is_reference(monitor_ref)
    end

    test "do not overwrite existing subscription", %{config: config} do
      test_pid = self()
      client = start_supervised!({Client, config})

      assert :ok = Client.subscribe(client, test_pid)
      listeners = :sys.get_state(client).mod_state.listeners

      assert :ok = Client.subscribe(client, test_pid)
      assert :sys.get_state(client).mod_state.listeners == listeners
    end
  end

  describe "unsubscribe/2" do
    setup :stub_successful_connection

    test "remove subscription", %{config: config} do
      test_pid = self()
      client = start_supervised!({Client, config})

      :ok = Client.subscribe(client, test_pid)

      assert %{^test_pid => _} = :sys.get_state(client).mod_state.listeners
      assert :ok = Client.unsubscribe(client, test_pid)
      assert :sys.get_state(client).mod_state.listeners == %{}
    end

    test "no-op when subscription not found", %{config: config} do
      test_pid = self()
      client = start_supervised!({Client, config})

      assert :sys.get_state(client).mod_state.listeners == %{}
      assert :ok = Client.unsubscribe(client, test_pid)
      assert :sys.get_state(client).mod_state.listeners == %{}
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
      {:ok, listener} =
        Task.start_link(fn ->
          Process.sleep(250)
        end)

      client = start_supervised!({Client, config})
      :ok = Client.subscribe(client, listener)

      assert %{^listener => monitor_ref} =
               :sys.get_state(client).mod_state.listeners

      assert is_reference(monitor_ref)

      assert eventually(fn ->
               map_size(:sys.get_state(client).mod_state.listeners) == 0
             end)

      verify!()
    end
  end

  describe "event handling" do
    Enum.each(Event.__event_types__(), fn event_type ->
      test "#{event_type} event", %{config: config} do
        socket = stub_successful_connection(config)

        client = start_supervised!({Client, config})
        :ok = Client.subscribe(client, self())

        assert eventually(fn -> Client.connected?(client) end)

        msg = "#{unquote(event_type)} system=Li01 base=Li01_01\r\n"

        expect_socket_set_to_active_once(socket)
        send_unicode_tcp_message(client, socket, msg)

        {:ok, event} = Event.parse(msg)
        assert_receive ^event

        eventually(fn -> verify!() end)
      end
    end)
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

    expect_socket_set_to_active_once(socket)

    socket
  end

  defp command_queued?(client) do
    :queue.len(:sys.get_state(client).mod_state.queue) > 0
  end

  defp expect_socket_set_to_active_once(socket, n \\ 1) do
    expect(MockInetAdapter, :setopts, n, fn ^socket, [active: :once] ->
      :ok
    end)
  end

  defp send_unicode_tcp_message(client, socket, msg) do
    {:ok, msg} = Codec.encode(:unicode, msg)
    send_tcp_message(client, socket, msg)
  end

  defp send_tcp_message(client, socket, msg) do
    send(client, {:tcp, socket, msg})
  end
end
