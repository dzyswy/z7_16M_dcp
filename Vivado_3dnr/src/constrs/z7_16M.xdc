
#---- clock ---- 
set_property PACKAGE_PIN    AB15            [get_ports {clk_27M_in}]
set_property IOSTANDARD     LVCMOS25        [get_ports {clk_27M_in}]

set_property PACKAGE_PIN    L3              [get_ports {clk_24M_in}]
set_property IOSTANDARD     LVCMOS18        [get_ports {clk_24M_in}]

#---- IIC ---- 
set_property PACKAGE_PIN 	AC26  		[get_ports {IIC_0_sda_io}]
set_property PACKAGE_PIN 	AB26  		[get_ports {IIC_0_scl_io}]

set_property IOSTANDARD 	LVCMOS33 	[get_ports {IIC_0_sda_io}]
set_property IOSTANDARD 	LVCMOS33 	[get_ports {IIC_0_scl_io}]

#---- sensor ---- 
#set_property PACKAGE_PIN    U22             [get_ports {sen_poweren}]
set_property PACKAGE_PIN      M1             [get_ports {sen_sysrstn}] 
set_property PACKAGE_PIN      N2             [get_ports {sen_sysstbn}]
set_property PACKAGE_PIN      J4             [get_ports {sen_inclk}]
set_property PACKAGE_PIN      L2             [get_ports {sen_sck}]
set_property PACKAGE_PIN      H2             [get_ports {sen_sdi}]
set_property PACKAGE_PIN      J1             [get_ports {sen_sdo}]
set_property PACKAGE_PIN      L4             [get_ports {sen_csn}]
set_property PACKAGE_PIN      H4             [get_ports {sen_vsync}]
set_property PACKAGE_PIN      M5             [get_ports {sen_hsync}]
set_property PACKAGE_PIN      M4             [get_ports {sen_trgexp}]
set_property PACKAGE_PIN      K2             [get_ports {sen_tout0}]

#set_property IOSTANDARD     LVCMOS33        [get_ports {sen_poweren}]
set_property IOSTANDARD     LVCMOS18        [get_ports {sen_sysrstn}] 
set_property IOSTANDARD     LVCMOS18        [get_ports {sen_sysstbn}]
set_property IOSTANDARD     LVCMOS18        [get_ports {sen_inclk}]
set_property IOSTANDARD     LVCMOS18        [get_ports {sen_sck}]
set_property IOSTANDARD     LVCMOS18        [get_ports {sen_sdi}]
set_property IOSTANDARD     LVCMOS18        [get_ports {sen_sdo}]
set_property IOSTANDARD     LVCMOS18        [get_ports {sen_csn}]
set_property IOSTANDARD     LVCMOS18        [get_ports {sen_vsync}]
set_property IOSTANDARD     LVCMOS18        [get_ports {sen_hsync}]
set_property IOSTANDARD     LVCMOS18        [get_ports {sen_trgexp}]
set_property IOSTANDARD     LVCMOS18        [get_ports {sen_tout0}]


set_property PACKAGE_PIN AC13 [get_ports sen_clkin_p] 

set_property PACKAGE_PIN	AE10		[get_ports {sen_datain_p[0]}]
set_property PACKAGE_PIN	Y17	        [get_ports {sen_datain_p[1]}]
set_property PACKAGE_PIN	AB11	    [get_ports {sen_datain_p[2]}]
set_property PACKAGE_PIN	AE11        [get_ports {sen_datain_p[3]}]
set_property PACKAGE_PIN	Y16 		[get_ports {sen_datain_p[4]}]
set_property PACKAGE_PIN	W13	 		[get_ports {sen_datain_p[5]}]
set_property PACKAGE_PIN	Y10		    [get_ports {sen_datain_p[6]}]
set_property PACKAGE_PIN	AE12	    [get_ports {sen_datain_p[7]}]
set_property PACKAGE_PIN	AB17		[get_ports {sen_datain_p[8]}]
set_property PACKAGE_PIN	AE17 		[get_ports {sen_datain_p[9]}]
set_property PACKAGE_PIN	AE13		[get_ports {sen_datain_p[10]}]
set_property PACKAGE_PIN	AF15 		[get_ports {sen_datain_p[11]}]
set_property PACKAGE_PIN	Y12		    [get_ports {sen_datain_p[12]}]
set_property PACKAGE_PIN	AD16 		[get_ports {sen_datain_p[13]}]
set_property PACKAGE_PIN	AA13		[get_ports {sen_datain_p[14]}]
set_property PACKAGE_PIN	AE16 		[get_ports {sen_datain_p[15]}]



set_property IOSTANDARD LVDS_25     [get_ports sen_clkin_p]
set_property IOSTANDARD LVDS_25     [get_ports {sen_datain_p[*]}]

create_clock -add -name sen_clkin_p -period 3.527 [get_ports sen_clkin_p] 

#---- sdi ---- 
set_property PACKAGE_PIN R6     [get_ports i_sdi_gt_refclk0_p] 
set_property PACKAGE_PIN U6     [get_ports i_sdi_gt_refclk1_p] 
set_property PACKAGE_PIN AA2    [get_ports sdi_txp]
set_property PACKAGE_PIN AA1    [get_ports sdi_txn]
set_property PACKAGE_PIN AB4    [get_ports sdi_rxp]
set_property PACKAGE_PIN AB3    [get_ports sdi_rxn]

create_clock -period 6.734 -waveform {0.0000 3.333} -name bank111_refclk0_i [get_ports i_sdi_gt_refclk0_p]
create_clock -period 6.734 -waveform {0.0000 3.333} -name bank111_refclk1_i [get_ports i_sdi_gt_refclk1_p]




#---- clock groups ---- 
set_clock_groups -name clk_gup0 -asynchronous -group [get_clocks -of_objects [get_pins u_system_wrapper/system_i/zynq/processing_system7_0/FCLK_CLK0]] -group [get_clocks -of_objects [get_pins u_system_wrapper/system_i/zynq/processing_system7_0/FCLK_CLK1]]
set_clock_groups -name clk_gup1 -asynchronous -group [get_clocks -of_objects [get_pins u_system_wrapper/system_i/zynq/processing_system7_0/FCLK_CLK0]] -group [get_clocks -of_objects [get_pins u_sensor/u_rx/rxc/bufr_div12/O]]
set_clock_groups -name clk_gup2 -asynchronous -group [get_clocks -of_objects [get_pins u_system_wrapper/system_i/zynq/processing_system7_0/FCLK_CLK0]] -group [get_clocks -of_objects [get_pins u_sensor/u_rx/rxc/bufr_div6/O]]
set_clock_groups -name clk_gup3 -asynchronous -group [get_clocks -of_objects [get_pins u_system_wrapper/system_i/zynq/processing_system7_0/FCLK_CLK0]] -group [get_clocks -of_objects [get_pins u_clk_wiz_0/inst/mmcm_adv_inst/CLKOUT0]]



