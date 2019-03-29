defmodule V60Examples do

  # id 2015/0x7DF TesterFunctionalReqHS
  # id 1830/0x726 TesterPhysicalReqCEMHSdef v60_read_in_car_temp() do
    #   setup_diagnostics("TesterFunctionalReqHS", "TesterPhysicalResCEMHS", flow_mode: :auto)
    #   # 3 bytes
    #   # 0x22 read data by identinifier (Service id)
    #   # 0x1f90 did for vin number (Data identifier)
    #   sendraw(<<0x03, @read_data_by_identifier 0xDD, 0x04, 0x00, 0x00, 0x00, 0x00>>)
    # end
  # id 1838/0x72E TesterPhysicalResCEMHS

  @read_data_by_identifier 0x22

  def v60_read_vin() do
    Diagnostics.setup_diagnostics("TesterPhysicalReqCEMHS", "TesterPhysicalResCEMHS", [flow_mode: :auto], :can0)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    # 0x1f90 did for vin number (Data identifier)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0xF190::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  # same again but defaults to default namespace which is specified on the config file.
  def v60_read_vin_default() do
    Diagnostics.setup_diagnostics("TesterPhysicalReqCEMHS", "TesterPhysicalResCEMHS", [flow_mode: :auto])
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    # 0x1f90 did for vin number (Data identifier)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0xF190::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v60_read_fuel_lid_latch_status() do
    Diagnostics.setup_diagnostics("TesterFunctionalReqHS", "TesterPhysicalResCEMHS", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0xEFFC::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v60_read_in_car_temp() do
    Diagnostics.setup_diagnostics("TesterFunctionalReqHS", "TesterPhysicalResCEMHS", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0xDD04::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v60_read_in_car_temp_outside() do
    Diagnostics.setup_diagnostics("TesterFunctionalReqHS", "TesterPhysicalResCEMHS", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0xDD05::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v60_air_condition_on_switch() do
    Diagnostics.setup_diagnostics("TesterFunctionalReqHS", "TesterPhysicalResCEMHS", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0x99A3::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v60_break() do
    Diagnostics.setup_diagnostics("TesterFunctionalReqHS", "TesterPhysicalResCEMHS", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0x404E::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v60_key() do
    Diagnostics.setup_diagnostics("TesterFunctionalReqHS", "TesterPhysicalResCEMHS", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0x411F::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  def v60_accpedal() do
    Diagnostics.setup_diagnostics("TesterFunctionalReqHS", "TesterPhysicalResCEMHS", flow_mode: :auto)
    # 3 bytes
    # 0x22 read data by identinifier (Service id)
    Diagnostics.sendraw(<<0x03, @read_data_by_identifier, 0xF449::size(16), 0x00, 0x00, 0x00, 0x00>>)
  end

  # kupenät
  # def v60_CCM_cabin_temp() do
  #   Diagnostics.setup_diagnostics("TesterPhysicalReqCCM", "TesterPhysicalResCCM", flow_mode: :auto)
  #   # 3 bytes
  #   # 0x22 read data by identinifier (Service id)
  #   # 0x1f90 did for vin number (Data identifier)
  #   Diagnostics.sendraw(<<0x03, @read_data_by_identifier 0x9A1B::size(16), 0x00, 0x00, 0x00, 0x00>>)
  # end
end
