defmodule V542Examples do

  # id 2047/0x7FF CemToAllFuncBodyDiagReqFrame
  # id 1809/0x711 CemToCcmBodyDiagReqFrame def v542_read_in_car_temp() do
    #   setup_diagnostics("CemToAllFuncBodyDiagReqFrame", "CcmToCemBodyDiagResFrame", flow_mode: :auto)
    #   # 3 bytes
    #   # 0x22 read data by identinifier (Service id)
    #   # 0x1f90 did for vin number (Data identifier)
    #   sendraw(<<0x03, @read_data_by_identifier 0xDD, 0x04, 0x00, 0x00, 0x00, 0x00>>)
    # end
  # id 1553/0x611 CcmToCemBodyDiagResFrame

  # operates on BodyCANhs, barely tested

  @read_data_by_identifier 0x22

  def v542_read_vin() do
    Diagnostics.setup_diagnostics("CemToCcmBodyDiagReqFrame ", "CcmToCemBodyDiagResFrame", [flow_mode: :auto], :can0)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    # 0x1f90 did for vin number (Data identifier)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0xF190::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  # same again but defaults to default namespace which is specified on the config file.
  def v542_read_vin_default() do
    Diagnostics.setup_diagnostics("CemToCcmBodyDiagReqFrame ", "CcmToCemBodyDiagResFrame", [flow_mode: :auto])
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    # 0x1f90 did for vin number (Data identifier)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0xF190::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v542_read_fuel_lid_latch_status() do
    Diagnostics.setup_diagnostics("CemToAllFuncBodyDiagReqFrame", "CcmToCemBodyDiagResFrame", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0xEFFC::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v542_read_in_car_temp() do
    Diagnostics.setup_diagnostics("CemToAllFuncBodyDiagReqFrame", "CcmToCemBodyDiagResFrame", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0xDD04::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v542_read_in_car_temp_outside() do
    Diagnostics.setup_diagnostics("CemToAllFuncBodyDiagReqFrame", "CcmToCemBodyDiagResFrame", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0xDD05::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v542_air_condition_on_switch() do
    Diagnostics.setup_diagnostics("CemToAllFuncBodyDiagReqFrame", "CcmToCemBodyDiagResFrame", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0x99A3::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v542_break() do
    Diagnostics.setup_diagnostics("CemToAllFuncBodyDiagReqFrame", "CcmToCemBodyDiagResFrame", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0x404E::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v542_key() do
    Diagnostics.setup_diagnostics("CemToAllFuncBodyDiagReqFrame", "CcmToCemBodyDiagResFrame", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0x411F::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v542_accpedal() do
    Diagnostics.setup_diagnostics("CemToAllFuncBodyDiagReqFrame", "CcmToCemBodyDiagResFrame", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0xF449::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

end
