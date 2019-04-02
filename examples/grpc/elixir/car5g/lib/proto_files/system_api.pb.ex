defmodule Base.SystemService.Service do
  @moduledoc false
  use GRPC.Service, name: "base.SystemService"

  rpc :GetConfiguration, Base.Empty, Base.Configuration
  rpc :ListSignals, Base.NameSpace, Base.Frames
end

defmodule Base.SystemService.Stub do
  @moduledoc false
  use GRPC.Stub, service: Base.SystemService.Service
end

