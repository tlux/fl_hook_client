defmodule FLHook.CodecTest do
  use ExUnit.Case, async: true

  alias FLHook.Codec
  alias FLHook.CodecError

  describe "decode/2" do
    test "success" do
      assert Codec.decode(:unicode, <<79, 0, 75, 0>>) == {:ok, "OK"}
    end

    test "unknown codec" do
      assert Codec.decode(:unicode, "invalid") ==
               {:error,
                %CodecError{
                  codec: :unicode,
                  direction: :decode,
                  value: "invalid"
                }}
    end

    test "decode error" do
      assert Codec.decode(:invalid, "invalid") ==
               {:error,
                %CodecError{
                  codec: :invalid,
                  direction: :decode,
                  value: "invalid"
                }}
    end
  end

  describe "encode/2" do
    test "success" do
      assert Codec.encode(:unicode, "OK") == {:ok, <<79, 0, 75, 0>>}
    end

    test "encode error" do
      assert Codec.encode(:invalid, "invalid") ==
               {:error,
                %CodecError{
                  codec: :invalid,
                  direction: :encode,
                  value: "invalid"
                }}
    end
  end
end
