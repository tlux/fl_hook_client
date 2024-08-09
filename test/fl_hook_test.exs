defmodule FLHookTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  @config %FLHook.Config{password: "test"}
  @client_timeout 30_000
  @response_error %FLHook.ResponseError{detail: "Something went wrong"}

  test "connect/1" do
    result = {:ok, self()}

    expect(FLHook.MockClient, :start_link, fn @config -> result end)

    assert FLHook.connect(@config) == result
  end

  test "connect/2" do
    result = {:ok, self()}
    opts = [name: Foo]

    expect(FLHook.MockClient, :start_link, fn @config, ^opts -> result end)

    assert FLHook.connect(@config, opts) == result
  end

  test "disconnect/2" do
    expect(FLHook.MockClient, :close, fn :client, @client_timeout -> :ok end)

    assert FLHook.disconnect(:client, @client_timeout) == :ok
  end

  test "connected?/2" do
    expect(FLHook.MockClient, :connected?, fn :client, @client_timeout ->
      true
    end)

    assert FLHook.connected?(:client, @client_timeout) == true
  end

  test "event_mode?/2" do
    expect(FLHook.MockClient, :event_mode?, fn :client, @client_timeout ->
      false
    end)

    assert FLHook.event_mode?(:client, @client_timeout) == false
  end

  test "exec/3" do
    expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
      {:ok, ["bar"]}
    end)

    assert FLHook.exec(:client, "foo", @client_timeout) == {:ok, ["bar"]}
  end

  describe "exec!/3" do
    test "success" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["bar"]}
      end)

      assert FLHook.exec!(:client, "foo", @client_timeout) == ["bar"]
    end

    test "error" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:error, @response_error}
      end)

      error =
        assert_raise FLHook.ResponseError, fn ->
          FLHook.exec!(:client, "foo", @client_timeout)
        end

      assert error == @response_error
    end
  end

  describe "run/3" do
    test "success" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["bar"]}
      end)

      assert FLHook.run(:client, "foo", @client_timeout) == :ok
    end

    test "error" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:error, @response_error}
      end)

      assert FLHook.run(:client, "foo", @client_timeout) ==
               {:error, @response_error}
    end
  end

  describe "run!/3" do
    test "success" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["bar"]}
      end)

      assert FLHook.run!(:client, "foo", @client_timeout) == :ok
    end

    test "error" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:error, @response_error}
      end)

      error =
        assert_raise FLHook.ResponseError, fn ->
          FLHook.run!(:client, "foo", @client_timeout)
        end

      assert error == @response_error
    end
  end

  describe "all/4" do
    test "success" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["id=foo", "id=bar"]}
      end)

      assert FLHook.all(:client, "foo", [], @client_timeout) ==
               {:ok,
                [
                  %{"id" => "foo"},
                  %{"id" => "bar"}
                ]}
    end

    test "with dict parse options" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["text=foo", "text=hello world"]}
      end)

      assert FLHook.all(:client, "foo", [expand: "text"], @client_timeout) ==
               {:ok,
                [
                  %{"text" => "foo"},
                  %{"text" => "hello world"}
                ]}
    end

    test "error" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:error, @response_error}
      end)

      assert FLHook.all(:client, "foo", [], @client_timeout) ==
               {:error, @response_error}
    end
  end

  describe "all!/4" do
    test "success" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["id=foo", "id=bar"]}
      end)

      assert FLHook.all!(:client, "foo", [], @client_timeout) == [
               %{"id" => "foo"},
               %{"id" => "bar"}
             ]
    end

    test "error" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:error, @response_error}
      end)

      error =
        assert_raise FLHook.ResponseError, fn ->
          FLHook.all!(:client, "foo", [], @client_timeout) ==
            {:error, @response_error}
        end

      assert error == @response_error
    end
  end

  describe "one/4" do
    test "success" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["id=foo", "id=bar"]}
      end)

      assert FLHook.one(:client, "foo", [], @client_timeout) ==
               {:ok, %{"id" => "foo"}}
    end

    test "no result" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, []}
      end)

      assert FLHook.one(:client, "foo", [], @client_timeout) ==
               {:ok, nil}
    end

    test "with dict parse options" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["text=hello world", "text=foo"]}
      end)

      assert FLHook.one(:client, "foo", [expand: "text"], @client_timeout) ==
               {:ok, %{"text" => "hello world"}}
    end

    test "error" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:error, @response_error}
      end)

      assert FLHook.one(:client, "foo", [], @client_timeout) ==
               {:error, @response_error}
    end
  end

  describe "one!/4" do
    test "success" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["id=foo", "id=bar"]}
      end)

      assert FLHook.one!(:client, "foo", [], @client_timeout) ==
               %{"id" => "foo"}
    end

    test "error" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:error, @response_error}
      end)

      error =
        assert_raise FLHook.ResponseError, fn ->
          FLHook.one!(:client, "foo", [], @client_timeout) ==
            {:error, @response_error}
        end

      assert error == @response_error
    end
  end

  describe "single/4" do
    test "success" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["id=foo"]}
      end)

      assert FLHook.single(:client, "foo", [], @client_timeout) ==
               {:ok, %{"id" => "foo"}}
    end

    test "no result" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, []}
      end)

      assert FLHook.single(:client, "foo", [], @client_timeout) ==
               {:error, %FLHook.RowsCountError{actual: 0, expected: 1}}
    end

    test "too many results" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["id=foo", "id=bar"]}
      end)

      assert FLHook.single(:client, "foo", [], @client_timeout) ==
               {:error, %FLHook.RowsCountError{actual: 2, expected: 1}}
    end

    test "with dict parse options" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["text=hello world"]}
      end)

      assert FLHook.single(:client, "foo", [expand: "text"], @client_timeout) ==
               {:ok, %{"text" => "hello world"}}
    end

    test "error" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:error, @response_error}
      end)

      assert FLHook.single(:client, "foo", [], @client_timeout) ==
               {:error, @response_error}
    end
  end

  describe "single!/4" do
    test "success" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:ok, ["id=foo"]}
      end)

      assert FLHook.single!(:client, "foo", [], @client_timeout) ==
               %{"id" => "foo"}
    end

    test "error" do
      expect(FLHook.MockClient, :cmd, fn :client, "foo", @client_timeout ->
        {:error, @response_error}
      end)

      error =
        assert_raise FLHook.ResponseError, fn ->
          FLHook.single!(:client, "foo", [], @client_timeout) ==
            {:error, @response_error}
        end

      assert error == @response_error
    end
  end

  test "subscribe/3" do
    expect(FLHook.MockClient, :subscribe, fn :client,
                                             :listener,
                                             @client_timeout ->
      :ok
    end)

    assert FLHook.subscribe(:client, :listener, @client_timeout) == :ok
  end

  test "unsubscribe/3" do
    expect(FLHook.MockClient, :unsubscribe, fn :client,
                                               :listener,
                                               @client_timeout ->
      :ok
    end)

    assert FLHook.unsubscribe(:client, :listener, @client_timeout) == :ok
  end
end
