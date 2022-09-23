defmodule OpenTelemetryGRPC.Interceptors.Client.OpenTelemetryTest do
  use ExUnit.Case, async: true

  require OpenTelemetry.Tracer
  require Record

  defmodule RouteGuide.Server do
    use GRPC.Server, service: Routeguide.RouteGuide.Service

    def get_feature(_request, _stream) do
      Routeguide.Feature.new(name: "A", location: Routeguide.Point.new(latitude: 1, longitude: 2))
    end
  end

  defmodule RouteGuide.Endpoint do
    use GRPC.Endpoint

    run RouteGuide.Server
  end

  for {name, spec} <- Record.extract_all(from_lib: "opentelemetry/include/otel_span.hrl") do
    Record.defrecord(name, spec)
  end

  for {name, spec} <- Record.extract_all(from_lib: "opentelemetry_api/include/opentelemetry.hrl") do
    Record.defrecord(name, spec)
  end

  setup :setup_opentelemetry
  setup :setup_grpc

  setup do
    # TODO: Change supervisor config after bump grpc to version 0.6.
    start_supervised!({GRPC.Server.Supervisor, {RouteGuide.Endpoint, 50051}})

    %{}
  end

  setup do
    OpenTelemetry.Tracer.start_span("test")

    on_exit(fn ->
      OpenTelemetry.Tracer.end_span()
    end)
  end

  test "add span to client" do
    {:ok, channel} =
      GRPC.Stub.connect("localhost:50051", interceptors: [GRPC.Client.Interceptors.OpenTelemetry])

    request = Routeguide.Point.new(latitude: 1, longitude: 2)
    # Ensure interceptor still return a result.
    assert {:ok, %Routeguide.Feature{name: "A"}} =
             Routeguide.RouteGuide.Stub.get_feature(channel, request)

    assert_receive {:span,
                    span(
                      name: "routeguide.RouteGuide/GetFeature",
                      kind: :client,
                      attributes: attributes,
                      events: events,
                      status: status
                    )}

    assert {_, _, _, _,
            %{
              "net.peer.name": "localhost",
              "net.peer.port": 50051,
              "net.transport": :tcp_ip,
              "rpc.method": "GetFeature",
              "rpc.service": "routeguide.RouteGuide",
              "rpc.system": :grpc,
              "rpc.grpc.status_code": 0
            }} = attributes

    assert {_, _, _, _, _,
            [{:event, _, :message, {:attributes, _, _, _, %{"message.type": "SENT"}}}]} = events

    assert {_, :ok, ""} = status
  end

  defp setup_opentelemetry(_context) do
    Application.stop(:opentelemetry)
    Application.put_env(:opentelemetry, :tracer, :otel_tracer_default)

    Application.put_env(:opentelemetry, :processors, [
      {:otel_batch_processor, %{scheduled_delay_ms: 1, exporter: {:otel_exporter_pid, self()}}}
    ])

    Application.start(:opentelemetry)
  end

  # TODO: Remove this configuration after bump grpc to version 0.6.
  defp setup_grpc(_context) do
    Application.stop(:grpc)
    Application.put_env(:grpc, :start_server, true)
    Application.start(:grpc)
  end
end
