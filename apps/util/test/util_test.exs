defmodule UtilTest do
  use ExUnit.Case

  describe "Forwarder" do
    test "initialize" do
      {:ok, p} = Util.Forwarder.start_link()
      assert Process.alive?(p) == true
      Util.Forwarder.setup(self())
      assert Util.Forwarder.terminate() == :ok
    end

    test "send and receive" do
      {:ok, _} = Util.Forwarder.start_link()
      Util.Forwarder.setup(self())

      Util.Forwarder.send(:something)
      assert Util.Forwarder.receive() == :something

      assert Util.Forwarder.terminate() == :ok
    end

    test "asynchorous worker" do
      Util.Forwarder.start_link()
      Util.Forwarder.setup(self())

      {:ok, a} = AsynchronousCaller.start_link()

      AsynchronousCaller.trigger(a, :heres_something)
      assert Util.Forwarder.receive() == :heres_something

      assert Util.Forwarder.terminate() == :ok
      assert GenServer.stop(a) == :ok
    end
  end

  describe "Config" do
    test "load" do
      {:ok, _} = Util.Config.start_link("config/test1.json")
      assert GenServer.stop(Util.Config) == :ok
    end

    test "parse IP" do
      assert Util.Config.parse_ip_string("127.0.0.1") == '127.0.0.1'
      assert Util.Config.parse_ip_string("192.168.100.1") == '192.168.100.1'
      assert Util.Config.parse_ip_string("my_hostname") == 'my_hostname'
    end

    test "test condition" do
      # Always true in test cases
      assert Util.Config.is_test() == true
    end
  end
end
