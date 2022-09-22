defmodule OpenTelemetryGRPC do
  @moduledoc """
  The OpenTelemetry interceptor for Elixir GRPC.

  ## Setup client-side interceptor.

  Add `GRPC.Client.Interceptors.OpenTelemetry` to `:interceptors` option when
  calling `GRPC.Stub.connect/2`:

      GRPC.Stub.connect("host:port", interceptors: [GRPC.Client.Interceptors.OpenTelemetry])
  """
end
