Read this in other languages: [English](README.md), [Japanese](README.ja.md)

# SiTCP Sample Code for KC705 GMII

This is the SiTCP sample source code (GMII version) for KC705 communication confirmation.

In this code use the module that converts the interface of AT93C46, used by SiTCP, to EEPROM (M24C08) of KC705.

This code also use a module that to operate I2C switch, PCA9548A, loaded on the KC705.

Before downloading the firmware to the KC705, please set the jumper connection of J29, J30, J64 of KC705 as follows.

* J29: Jumper over pins No.1-2.
* J30: Jumper over pins No.1-2.
* J64: No jumper.

(Please see at reference Xilinx UG 810 for more information).

When using VIVADO, please use EDF files as NGC files cannot be used.


## What is SiTCP

Simple TCP/IP implemented on an FPGA (Field Programmable Gate Array) for the purpose of transferring large amounts of data in physics experiments.

* For details, please refer to [SiTCP Library page](https://www.bbtech.co.jp/en/products/sitcp-library/).
* For other related projects, please refer to [here](https://github.com/BeeBeansTechnologies).

![SiTCP](sitcp.png)


## History

#### 2025-11-11 Ver.1.0.2

* "EDF_SiTCP.xdc"
     * New addition.
* "SiTCP_XC7K_32K_BBT_V110.edf"
     * New addition.

#### 2022-06-07 Ver.1.0.1

* "Kc705sitcp.v"
     * Corrected the port name.
     * Changed system reset statement.
     * Assigned ForceDefault to the DIP switch.
     * Instantiated RBCP module.
     * Added DIP switch assignment.
* "RBCP.v"
     * New addition.
* "Kc705sitcp.xdc"
     * Corrected the port name.
     * Added constraints.

#### 2018-11-12 Ver.1.0.0

* First release.