defmodule FLHook.CodecTest do
  use ExUnit.Case, async: true

  alias FLHook.Codec
  alias FLHook.CodecError

  describe "decode/2" do
    test "success" do
      assert Codec.decode(FLHook.Codecs.UTF16LE, <<79, 0, 75, 0>>) ==
               {:ok, "OK"}
    end

    test "decode error" do
      assert Codec.decode(FLHook.Codecs.UTF16LE, <<0>>) ==
               {:error,
                %CodecError{
                  codec: FLHook.Codecs.UTF16LE,
                  direction: :decode,
                  value: <<0>>
                }}
    end
  end

  describe "encode/2" do
    test "success" do
      assert Codec.encode(FLHook.Codecs.UTF16LE, "OK") ==
               {:ok, <<79, 0, 75, 0>>}
    end
  end
end
