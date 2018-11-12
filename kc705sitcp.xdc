

set_property IOSTANDARD LVCMOS25 [get_ports GMII_COL]
set_property IOSTANDARD LVCMOS25 [get_ports GMII_CRS]
set_property IOSTANDARD LVCMOS25 [get_ports GMII_GTXCLK]
set_property IOSTANDARD LVCMOS25 [get_ports GMII_MDC]
set_property IOSTANDARD LVCMOS25 [get_ports GMII_MDIO]
set_property IOSTANDARD LVCMOS25 [get_ports GMII_RSTn]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_RXD[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_RXD[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_RXD[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_RXD[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_RXD[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_RXD[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_RXD[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_RXD[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports GMII_RX_CLK]
set_property IOSTANDARD LVCMOS25 [get_ports GMII_RX_DV]
set_property IOSTANDARD LVCMOS25 [get_ports GMII_RX_ER]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_TXD[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_TXD[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_TXD[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_TXD[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_TXD[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_TXD[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_TXD[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GMII_TXD[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports GMII_TX_CLK]
set_property IOSTANDARD LVCMOS25 [get_ports GMII_TX_EN]
set_property IOSTANDARD LVCMOS25 [get_ports GMII_TX_ER]
set_property IOSTANDARD LVCMOS25 [get_ports I2C_SDA]
set_property IOSTANDARD LVCMOS25 [get_ports I2C_SCL]
set_property IOSTANDARD LVCMOS25 [get_ports GPIO_SWITCH_0]
set_property IOSTANDARD LVCMOS15 [get_ports SW_N]
set_property IOSTANDARD LVDS [get_ports SYSCLK_200MP_IN]
set_property IOSTANDARD LVDS [get_ports SYSCLK_200MN_IN]


set_property PACKAGE_PIN AD11 [get_ports SYSCLK_200MN_IN]
set_property PACKAGE_PIN AD12 [get_ports SYSCLK_200MP_IN]
set_property PACKAGE_PIN L20 [get_ports GMII_RSTn]
set_property PACKAGE_PIN M27 [get_ports GMII_TX_EN]
set_property PACKAGE_PIN N27 [get_ports {GMII_TXD[0]}]
set_property PACKAGE_PIN N25 [get_ports {GMII_TXD[1]}]
set_property PACKAGE_PIN M29 [get_ports {GMII_TXD[2]}]
set_property PACKAGE_PIN L28 [get_ports {GMII_TXD[3]}]
set_property PACKAGE_PIN J26 [get_ports {GMII_TXD[4]}]
set_property PACKAGE_PIN K26 [get_ports {GMII_TXD[5]}]
set_property PACKAGE_PIN L30 [get_ports {GMII_TXD[6]}]
set_property PACKAGE_PIN J28 [get_ports {GMII_TXD[7]}]
set_property PACKAGE_PIN N29 [get_ports GMII_TX_ER]
set_property PACKAGE_PIN U27 [get_ports GMII_RX_CLK]
set_property PACKAGE_PIN R28 [get_ports GMII_RX_DV]
set_property PACKAGE_PIN U30 [get_ports {GMII_RXD[0]}]
set_property PACKAGE_PIN U25 [get_ports {GMII_RXD[1]}]
set_property PACKAGE_PIN T25 [get_ports {GMII_RXD[2]}]
set_property PACKAGE_PIN U28 [get_ports {GMII_RXD[3]}]
set_property PACKAGE_PIN R19 [get_ports {GMII_RXD[4]}]
set_property PACKAGE_PIN T27 [get_ports {GMII_RXD[5]}]
set_property PACKAGE_PIN T26 [get_ports {GMII_RXD[6]}]
set_property PACKAGE_PIN T28 [get_ports {GMII_RXD[7]}]
set_property PACKAGE_PIN V26 [get_ports GMII_RX_ER]
set_property PACKAGE_PIN R30 [get_ports GMII_CRS]
set_property PACKAGE_PIN W19 [get_ports GMII_COL]
set_property PACKAGE_PIN J21 [get_ports GMII_MDIO]
set_property PACKAGE_PIN K30 [get_ports GMII_GTXCLK]
set_property PACKAGE_PIN M28 [get_ports GMII_TX_CLK]
set_property PACKAGE_PIN R23 [get_ports GMII_MDC]
set_property PACKAGE_PIN L21 [get_ports I2C_SDA]
set_property PACKAGE_PIN K21 [get_ports I2C_SCL]
set_property PACKAGE_PIN Y29 [get_ports GPIO_SWITCH_0]
set_property PACKAGE_PIN AA12 [get_ports SW_N]

create_clock -period 5.000 -name SYSCLK_200MP_IN -waveform {0.000 2.500} [get_ports SYSCLK_200MP_IN]
create_clock -period 40.000 -name GMII_TX_CLK -waveform {0.000 20.000} [get_ports GMII_TX_CLK]
create_clock -period 8.000 -name GMII_RX_CLK -waveform {0.000 4.000} [get_ports GMII_RX_CLK]
set_clock_groups -group [get_clocks GMII_TX_CLK] -group [get_clocks CLK_125M] -logically_exclusive

set_false_path -from [get_pins CNT_RST_reg/C] -to [get_pins RX_CNT_reg*/CLR]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 6 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]


set_max_delay -datapath_only -from [get_pins {RX_CNT_reg[6]/C}] -to [get_pins GMII_1000M_reg/D] 5.000

set_false_path -from [get_pins GMII_1000M_reg/C]
set_false_path -through [get_nets RST_EEPROM]

set_property IOB false [get_cells -hierarchical -filter {name =~ */GMII_RXCNT/IOB_RD_*}]
set_property IOB false [get_cells -hierarchical -filter {name =~ */GMII_RXCNT/IOB_RDV}]
set_property IOB false [get_cells -hierarchical -filter {name =~ */GMII_RXCNT/IOB_RERR}]

set_input_delay -clock [get_clocks GMII_RX_CLK] -min 0.5 [get_port GMII_RXD*]
set_input_delay -clock [get_clocks GMII_RX_CLK] -min 0.5 [get_port GMII_RX_ER]
set_input_delay -clock [get_clocks GMII_RX_CLK] -min 0.5 [get_port GMII_RX_DV]
set_input_delay -clock [get_clocks GMII_RX_CLK] -max 5.5 [get_port GMII_RXD*]
set_input_delay -clock [get_clocks GMII_RX_CLK] -max 5.5 [get_port GMII_RX_ER]
set_input_delay -clock [get_clocks GMII_RX_CLK] -max 5.5 [get_port GMII_RX_DV]

set_max_delay -from [get_port GMII_MDIO] 10
set_min_delay -from [get_port GMII_MDIO] 0
set_max_delay -from [get_port I2C_SDA] 10
set_min_delay -from [get_port I2C_SDA] 0

set_property IOB true [get_cells -hierarchical -filter {name =~ */GMII_TXCNT/IOB_TD_*}]
set_property IOB true [get_cells -hierarchical -filter {name =~ */GMII_TXCNT/IOB_TEN}]

set_max_delay -from [get_clocks GMII_TX_CLK] -to [get_port GMII_TXD*] 30
set_min_delay -from [get_clocks GMII_TX_CLK] -to [get_port GMII_TXD*] 0
set_max_delay -from [get_clocks GMII_TX_CLK] -to [get_port GMII_TX_EN] 30
set_min_delay -from [get_clocks GMII_TX_CLK] -to [get_port GMII_TX_EN] 0
set_max_delay -from [get_clocks GMII_TX_CLK] -to [get_port GMII_TX_ER] 30
set_min_delay -from [get_clocks GMII_TX_CLK] -to [get_port GMII_TX_ER] 0


set_max_delay -datapath_only -from [get_clocks CLK_125M] -to [get_port GMII_GTXCLK] 3.2
set_max_delay -datapath_only -from [get_clocks CLK_125M] -to [get_port GMII_TX_EN] 3.2
set_max_delay -datapath_only -from [get_clocks CLK_125M] -to [get_port GMII_TXD*] 3.2
set_max_delay -datapath_only -from [get_clocks CLK_125M] -to [get_port GMII_TX_ER] 3.2

set_max_delay -datapath_only -from [get_clocks SYSCLK_200MP_IN] -to [get_port GMII_MDC] 10
set_max_delay -datapath_only -from [get_clocks SYSCLK_200MP_IN] -to [get_port GMII_MDIO] 10
set_max_delay -datapath_only -from [get_clocks SYSCLK_200MP_IN] -to [get_port GMII_RSTn] 10
set_max_delay -datapath_only -from [get_clocks SYSCLK_200MP_IN] -to [get_port I2C_SCL] 10
set_max_delay -datapath_only -from [get_clocks SYSCLK_200MP_IN] -to [get_port I2C_SDA] 10

