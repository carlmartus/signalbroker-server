defmodule FakeCan.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    #AppFakeCan.start_link("fake", "recorded_can/candump-2017-06-19_112957.log", human_file: "configuration/human_files/cfile.json")
    AppFakeCan.start_link("fake",
                          "recorded_can/candump-2017-06-19_112957.log",
                          dbc_file: "apps/app_ngcan/config/EuCD031_YD_HS_CAN_R00.dbc")
  end
end
