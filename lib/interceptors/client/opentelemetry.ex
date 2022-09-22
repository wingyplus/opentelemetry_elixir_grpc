defmodule GRPC.Client.Interceptors.OpenTelemetry do
  @moduledoc """
  TODO: add doc.
  """

  alias GRPC.Client.Stream

  require OpenTelemetry.Tracer

  @behaviour GRPC.ClientInterceptor

  @impl true
  def init(opts), do: opts

  @impl true
  def call(stream, req, next, _opts) do
    OpenTelemetry.Tracer.with_span full_method(stream), %{kind: :client} do
      metadata =
        :opentelemetry.get_text_map_injector()
        |> :otel_propagator_text_map.inject(%{}, &set_metadata/3)

      stream
      |> GRPC.Client.Stream.put_headers(metadata)
      |> next.(req)
      |> set_span_attributes(stream)
    end
  end

  defp set_metadata(key, value, metadata) do
    Map.put(metadata, key, value)
  end

  defp full_method(%Stream{service_name: service_name, method_name: method_name}) do
    "#{service_name}/#{method_name}"
  end

  defp set_span_attributes(result, stream) do
    stream
    |> build_attributes()
    |> OpenTelemetry.Tracer.set_attributes()

    result
  end

  defp build_attributes(%Stream{
         service_name: service_name,
         method_name: method_name,
         channel: channel
       }) do
    %GRPC.Channel{host: host, port: port} = channel

    %{
      "rpc.system": :grpc,
      "rpc.service": service_name,
      "rpc.method": method_name,
      "net.peer.name": host,
      "net.peer.port": port,
      "net.transport": :tcp_ip
    }
  end
end
