defmodule FLHook.ClientTest do
  use ExUnit.Case

  import Liveness
  import Mox

  alias FLHook.Client
  alias FLHook.Codec
  alias FLHook.Config
  alias FLHook.MockInetAdapter
  alias FLHook.MockTCPAdapter

  setup :set_mox_global
  setup :verify_on_exit!

  describe "start_link/1" do
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

      assert eventually(fn ->
               :sys.get_state(client).mod_state.socket == fake_socket
             end)
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

      assert eventually(fn ->
               :sys.get_state(client).mod_state.socket == fake_socket
             end)
    end

    test "connect error"

    test "handshake error"

    test "auth error"

    test "event mode error"
  end
end
