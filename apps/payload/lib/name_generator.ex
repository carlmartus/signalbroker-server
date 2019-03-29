defmodule Payload.Name do

  # namespace is string
  def generate_name_from_namespace(namespace, :desc) do
    generate_name(namespace, "desc")
  end

  def generate_name_from_namespace(namespace, :server) do
    generate_name(namespace, "server")
  end

  def generate_name_from_namespace(namespace, :writer) do
    generate_name(namespace, "writer")
  end

  def generate_name_from_namespace(namespace, :signal) do
    generate_name(namespace, "signal")
  end

  def generate_name_from_namespace(namespace, :supervisor) do
    generate_name(namespace, "supervisor")
  end

  def generate_name_from_namespace(namespace, :scheduler) do
    generate_name(namespace, "scheduler")
  end

  def generate_name_from_namespace(namespace, :config_server) do
    generate_name(namespace, "config_server")
  end

  def generate_name_from_namespace(namespace, :cache) do
    SignalBase.Application.make_cache_name(namespace)
    # generate_name(namespace, "supervisor")
  end

  defp generate_name(namespace, suffix) when is_atom(namespace) do

    config = if Util.Config.is_test() do
      Util.Config.Test.get_test_config()
    else
      Util.Config.get_config()
    end

    [chain] =
      config.chains
      |> Enum.filter(fn(conf) ->
        String.to_atom(conf.namespace) == namespace
      end)

    case chain.type do
      "can" -> AppNgCan.Application.make_name(namespace, suffix)
      "udp" -> CanUdp.App.make_name(namespace, suffix)
      "lin" -> AppLin.make_name(namespace, suffix)
      "flexray" -> FlexRay.make_name(namespace, suffix)
      # TODO: vitual will end here, is that ok
      _ -> nil
    end
  end
end
