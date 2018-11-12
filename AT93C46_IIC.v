//----------------------------------------------------------------------//
//
//	Copyright (c) 2017 BeeBeans Technologies All rights reserved
//
//		System		: AC701
//
//		Module		: AT93C46_IIC
//
//		Description	: AT93C46 emulator using IIC memory with PCA9548
//
//		file		: AT93C46_IIC.v
//
//		Note		:
//
//		history	:
//			171004	------		Created by M.Ishiwata
//
//----------------------------------------------------------------------//
`default_nettype none
module
	AT93C46_IIC #(
		parameter	[ 6:0]	PCA9548_AD	= 7'b1110_100,	// PCA9548 Dvice Address
		parameter	[ 7:0]	PCA9548_SL	= 8'b0001_1000,	// PCA9548 Select code (Ch3,Ch4 enable)
		parameter	[ 6:0]	IIC_MEM_AD	= 7'b1010_100,	// IIC Memory Dvice Address
		parameter	[ 7:0]	FREQUENCY	= 8'd200,		// CLK_IN Frequency  > 10MHz
		parameter	integer	DRIVE		= 4,			// Output Buffer Strength
		parameter			IOSTANDARD	= "DEFAULT",	// I/O Standard
		parameter			SLEW		= "SLOW"		// Outputbufer Slew rate
	)(
		input	wire			CLK_IN,					// System Clock
		input	wire			RESET_IN,				// Reset
		output	reg				IIC_INIT_OUT,			// IIC , AT93C46 Initialize (0=Initialize End)
		input	wire			EEPROM_CS_IN,			// AT93C46 Chip select
		input	wire			EEPROM_SK_IN,			// AT93C46 Serial data clock
		input	wire			EEPROM_DI_IN,			// AT93C46 Serial write data (Master to Memory)
		output	reg				EEPROM_DO_OUT,			// AT93C46 Serial read data(Slave to Master)
		output	wire			INIT_ERR_OUT,			// PCA9548 Initialize Error
		input	wire			IIC_REQ_IN,				// IIC Request
		input	wire	[ 7:0]	IIC_NUM_IN,				// IIC Number of Access[7:0]	0x00:1Byte , 0xff:256Byte
		input	wire	[ 6:0]	IIC_DAD_IN,				// IIC Device Address[6:0]
		input	wire	[ 7:0]	IIC_ADR_IN,				// IIC Word Address[7:0]
		input	wire			IIC_RNW_IN,				// IIC Read(1) / Write(0)
		input	wire	[ 7:0]	IIC_WDT_IN,				// IIC Write Data[7:0]
		output	wire			IIC_RAK_OUT,			// IIC Request Acknowledge
		output	wire	 		IIC_WDA_OUT,			// IIC Wite Data Acknowledge(Next Data Request)
		output	wire	 		IIC_WAE_OUT,			// IIC Wite Last Data Acknowledge(same as IIC_WDA timing)
		output	wire			IIC_BSY_OUT,			// IIC Busy
		output	wire	[ 7:0]	IIC_RDT_OUT,			// IIC Read Data[7:0]
		output	wire			IIC_RVL_OUT,			// IIC Read Data Valid
		output	wire			IIC_EOR_OUT,			// IIC End of Read Data(same as IIC_RVL timing)
		output	wire			IIC_ERR_OUT,			// IIC Error Detect
		// Device Interface
		output	wire			IIC_SCL_OUT,			// IIC Clock
		inout	wire			IIC_SDA_IO				// IIC Data
	);

	reg		[ 7:0]	BOOT_CNT;

	reg				MEM_WEN;
	reg		[ 6:0]	MEM_WAD;
	reg		[ 8:0]	MEM_WDT;
	reg		[ 6:0]	MEM_RAD;
	wire	[ 8:0]	MEM_RDT;

	reg		[ 1:0]	MEM_REN;
	reg		[ 1:0]	MEM_RPL;
	reg		[ 1:0]	MEM_RVL;
	reg		[ 7:0]	MEM_GDT;
	reg				WBK_SET;
	reg		[ 7:0]	WBK_WDT;
	reg				WBK_REQ;
	reg				WBK_END;
	reg		[ 6:0]	WBK_ADR;


	reg		[ 1:0]	EROM_REQ;
	reg		[ 6:0]	EROM_NUM;
	reg		[ 6:0]	EROM_ADR;
	reg				EROM_RNW;
	reg		[ 7:0]	EROM_WDT;
	reg				EROM_INIT;
	reg		[ 6:0]	EROM_IAD;

	wire			EROM_RAK;
	wire			EROM_WDA;
	wire			EROM_WAE;
	wire			EROM_BSY;
	wire	[ 7:0]	EROM_RDT;
	wire			EROM_RVL;
	wire			EROM_EOR;
	wire			EROM_ERR;

	reg		[ 3:0]	SYNC_CS;
	reg		[ 3:0]	SYNC_SK;
	reg		[ 3:0]	SYNC_DI;
	reg				CMD_CS;
	reg		[ 1:0]	CMD_SK;
	reg				CMD_DI;
	reg				STA_BT;
	reg		[ 3:0]	CMD_CNT;
	reg		[ 3:0]	DAT_CNT;
	reg		[ 1:0]	MEM_CMD;
	reg		[ 7:0]	MEM_ADR;
	reg		[ 7:0]	MEM_SDT;
	reg				MEM_SET;
	reg				MEM_PRO;
	reg				PROTECT;
	reg				MEM_GET;
	reg				MEM_LOD;
	reg		[ 7:0]	OUT_SFT;

// Initialize
	always@(posedge CLK_IN or posedge RESET_IN)begin
		if (RESET_IN) begin
			BOOT_CNT[7:0]	<= 8'd0;
			IIC_INIT_OUT	<= 1;
		end else begin
			BOOT_CNT[7:0]	<= BOOT_CNT[7]?	8'b1000_0000:	(BOOT_CNT[7:0] + 8'd1);
			IIC_INIT_OUT	<= IIC_INIT_OUT & ~(EROM_REQ[0] & EROM_INIT & ~EROM_BSY & ~EROM_ERR);
		end
	end

// Memory Control
	always@(posedge CLK_IN or posedge RESET_IN)begin
		if (RESET_IN) begin
			MEM_WEN			<= 0;
			MEM_WAD[6:0]	<= 7'd0;
			MEM_WDT[8:0]	<= 9'd0;
			MEM_RAD[6:0]	<= 7'd0;
			MEM_REN[1:0]	<= 2'b00;
			MEM_RPL[1:0]	<= 2'b00;
			MEM_RVL[1:0]	<= 2'b00;
			MEM_GDT[7:0]	<= 8'd0;
			WBK_SET			<= 0;
			WBK_WDT[7:0]	<= 8'd0;
			WBK_REQ			<= 0;
			WBK_END			<= 0;
			WBK_ADR[6:0]	<= 7'd0;
		end else begin
			MEM_WEN			<= (
				( EROM_INIT & EROM_RVL)|
				(~EROM_INIT & MEM_SET)|
				(~EROM_INIT & WBK_SET)
			);
			MEM_WAD[6:0]	<= (
				(( EROM_INIT          )?	EROM_IAD[6:0]:	8'h00)|
				((~EROM_INIT &  MEM_SET)?	MEM_ADR[6:0]:	8'h00)|
				((~EROM_INIT & ~MEM_SET)?	WBK_ADR[6:0]:	8'h00)
			);
			MEM_WDT[8:0]	<= (
				(( EROM_INIT          )?	{1'b0,EROM_RDT[7:0]}:	{1'b0,8'h00})|
				((~EROM_INIT &  MEM_SET)?	{1'b1,MEM_SDT[7:0]}:	{1'b0,8'h00})|
				((~EROM_INIT & ~MEM_SET)?	{1'b0,WBK_WDT[7:0]}:	{1'b0,8'h00})
			);
			MEM_RAD[6:0]	<= MEM_GET?		MEM_ADR[6:0]:	WBK_ADR[6:0];
			MEM_REN[1]		<= ~IIC_INIT_OUT & ~MEM_SET & ~MEM_GET & ~MEM_REN[1] & ~MEM_RPL[1] & ~MEM_RVL[1] & ~WBK_SET & ~WBK_REQ & ~WBK_END;
			MEM_REN[0]		<= MEM_GET;
			MEM_RPL[1:0]	<= (MEM_SET?	2'b01:	2'b11) & MEM_REN[1:0];
			MEM_RVL[1:0]	<= (MEM_SET?	2'b01:	2'b11) & MEM_RPL[1:0];
			MEM_GDT[7:0]	<= MEM_RVL[0]?	MEM_RDT[7:0]:	MEM_GDT[7:0];
			WBK_SET			<= ~MEM_SET & MEM_RVL[1] &  MEM_RDT[8];
			WBK_WDT[7:0]	<= MEM_RVL[1]?	MEM_RDT[7:0]:	WBK_WDT[7:0];
			WBK_REQ			<= (~MEM_SET & WBK_SET)|(WBK_REQ & (EROM_REQ[0] | EROM_BSY));
			WBK_END			<= (WBK_REQ & ~EROM_REQ[0] & ~EROM_BSY)|(MEM_RVL[1] & ~MEM_RDT[8]);
			WBK_ADR[6:0]	<= WBK_ADR[6:0] + (WBK_END?		7'd1:	7'd0);
		end
	end

	BRAM128_9B9B		MIRROR_MEM(
		.clka		(CLK_IN),
		.wea		(MEM_WEN),
		.addra		(MEM_WAD[6:0]),
		.dina		(MEM_WDT[8:0]),
		.clkb		(CLK_IN),
		.addrb		(MEM_RAD[6:0]),
		.doutb		(MEM_RDT[8:0])
	);

	always@(posedge CLK_IN or posedge RESET_IN) begin
		if (RESET_IN) begin
			EROM_REQ[1:0]	<= 2'b00;
			EROM_NUM[6:0]	<= 7'd0;
			EROM_ADR[6:0]	<= 7'd0;
			EROM_RNW		<= 1'b0;
			EROM_WDT[7:0]	<= 8'd0;
			EROM_INIT		<= 1'b0;
			EROM_IAD[6:0]	<= 8'd0;
		end else begin
			EROM_REQ[0]	<= (
				(~EROM_REQ[0] & ~EROM_BSY &  IIC_INIT_OUT & BOOT_CNT[7])|
				(~EROM_REQ[0] & ~EROM_BSY & ~IIC_INIT_OUT & WBK_REQ)|
				( EROM_REQ[0] &  EROM_REQ[1])|
				( EROM_REQ[0] &  EROM_BSY)|
				( EROM_REQ[0] &  EROM_ERR)
			);
			EROM_REQ[1]	<= (
				(~EROM_REQ[0] & ~EROM_BSY &  IIC_INIT_OUT & BOOT_CNT[7])|
				(~EROM_REQ[0] & ~EROM_BSY & ~IIC_INIT_OUT & WBK_REQ)|
				( EROM_REQ[0] & ~EROM_REQ[1] & ~EROM_BSY & EROM_ERR)|
				( EROM_REQ[0] &  EROM_REQ[1] & ~EROM_RAK)
			);
			EROM_NUM[6:0]	<= EROM_REQ[0]?	EROM_NUM[6:0]:	(IIC_INIT_OUT?	7'd127:		7'd0);
			EROM_ADR[6:0]	<= EROM_REQ[0]?	EROM_ADR[6:0]:	(IIC_INIT_OUT?	7'd0:		WBK_ADR[6:0]);
			EROM_RNW		<= EROM_REQ[0]?	EROM_RNW:		(IIC_INIT_OUT?	1'b1:		1'b0);
			EROM_WDT[7:0]	<= EROM_REQ[0]?	EROM_WDT[7:0]:	WBK_WDT[7:0];
			EROM_INIT		<= (
				(EROM_RAK  & EROM_RNW)|		// Read = Initialize
				(EROM_INIT & EROM_BSY)
			);
			EROM_IAD[6:0]	<= EROM_INIT?	(EROM_IAD[6:0] + (EROM_RVL?		7'd1:	7'd0)):		7'd0;
		end
	end

	PCA9548_SW	#(
		.PCA9548_AD				(PCA9548_AD),			// PCA9548 Dvice Address
		.PCA9548_SL				(PCA9548_SL),			// PCA9548 Select code (Ch3,Ch4 enable)
		.FREQUENCY				(FREQUENCY),			// CLK_IN Frequency  > 10MHz
		.DRIVE					(DRIVE),				// Output Buffer Strength
		.IOSTANDARD				(IOSTANDARD),			// I/O Standard
		.SLEW					(SLEW)					// Outputbufer Slew rate
	)
	PCA9548_SW	(
		.CLK_IN					(CLK_IN),				// System Clock
		.RESET_IN				(RESET_IN),				// Reset
		.INIT_ERR_OUT			(INIT_ERR_OUT),			// PCA9548 Initialize Error
		// Ch0
		.IIC0_REQ_IN			(EROM_REQ[1]),			// IIC ch0 Request
		.IIC0_NUM_IN			({1'b0,EROM_NUM[6:0]}),	// IIC ch0 Number of Access[7:0]	0x00:1Byte , 0xff:256Byte
		.IIC0_DAD_IN			(IIC_MEM_AD),			// IIC ch0 Device Address[6:0]
		.IIC0_ADR_IN			({1'b0,EROM_ADR[6:0]}),	// IIC ch0 Word Address[7:0]
		.IIC0_RNW_IN			(EROM_RNW),				// IIC ch0 Read(1) / Write(0)
		.IIC0_WDT_IN			(EROM_WDT[7:0]),		// IIC ch0 Write Data[7:0]
		.IIC0_RAK_OUT			(EROM_RAK),				// IIC ch0 Request Acknowledge
		.IIC0_WDA_OUT			(EROM_WDA),				// IIC ch0 Wite Data Acknowledge(Next Data Request)
		.IIC0_WAE_OUT			(EROM_WAE),				// IIC ch0 Wite Last Data Acknowledge(same as IIC_WDA timing)
		.IIC0_BSY_OUT			(EROM_BSY),				// IIC ch0 Busy
		.IIC0_RDT_OUT			(EROM_RDT[7:0]),		// IIC ch0 Read Data[7:0]
		.IIC0_RVL_OUT			(EROM_RVL),				// IIC ch0 Read Data Valid
		.IIC0_EOR_OUT			(EROM_EOR),				// IIC ch0 End of Read Data(same as IIC_RVL timing)
		.IIC0_ERR_OUT			(EROM_ERR),				// IIC ch0 Error Detect
		// Ch1
		.IIC1_REQ_IN			(IIC_REQ_IN),			// IIC ch1 Request
		.IIC1_NUM_IN			(IIC_NUM_IN[7:0]),		// IIC ch1 Number of Access[7:0]	0x00:1Byte , 0xff:256Byte
		.IIC1_DAD_IN			(IIC_DAD_IN[6:0]),		// IIC ch1 Device Address[6:0]
		.IIC1_ADR_IN			(IIC_ADR_IN[7:0]),		// IIC ch1 Word Address[7:0]
		.IIC1_RNW_IN			(IIC_RNW_IN),			// IIC ch1 Read(1) / Write(0)
		.IIC1_WDT_IN			(IIC_WDT_IN[7:0]),		// IIC ch1 Write Data[7:0]
		.IIC1_RAK_OUT			(IIC_RAK_OUT),			// IIC ch1 Request Acknowledge
		.IIC1_WDA_OUT	 		(IIC_WDA_OUT),			// IIC ch1 Wite Data Acknowledge(Next Data Request)
		.IIC1_WAE_OUT	 		(IIC_WAE_OUT),			// IIC ch1 Wite Last Data Acknowledge(same as IIC_WDA timing)
		.IIC1_BSY_OUT			(IIC_BSY_OUT),			// IIC ch1 Busy
		.IIC1_RDT_OUT			(IIC_RDT_OUT[7:0]),	// IIC ch1 Read Data[7:0]
		.IIC1_RVL_OUT			(IIC_RVL_OUT),			// IIC ch1 Read Data Valid
		.IIC1_EOR_OUT			(IIC_EOR_OUT),			// IIC ch1 End of Read Data(same as IIC_RVL timing)
		.IIC1_ERR_OUT			(IIC_ERR_OUT),			// IIC ch1 Error Detect
		// Device Interface
		.IIC_SCL_OUT			(IIC_SCL_OUT),			// IIC Clock
		.IIC_SDA_IO				(IIC_SDA_IO)				// IIC Data
	);

// AT93C46 Emulator
	always@(posedge CLK_IN or posedge RESET_IN)begin
		if (RESET_IN) begin
			SYNC_CS[3:0]	<= 4'b0000;
			SYNC_SK[3:0]	<= 4'b0000;
			SYNC_DI[3:0]	<= 4'b0000;
			CMD_CS			<= 0;
			CMD_SK[1:0]		<= 2'b00;
			CMD_DI			<= 0;
			STA_BT			<= 0;
			CMD_CNT[3:0]	<= 4'b0000;
			DAT_CNT[3:0]	<= 4'b0001;
			MEM_CMD[1:0]	<= 2'b00;
			MEM_ADR[7:0]	<= 8'b0000_0000;
			MEM_SDT[7:0]	<= 8'b0000_0000;
			MEM_SET			<= 0;
			MEM_PRO			<= 0;
			PROTECT			<= 1;
			MEM_GET			<= 0;
			MEM_LOD			<= 0;
			OUT_SFT[7:0]	<= 8'b1111_1111;
			EEPROM_DO_OUT	<= 1'b1;
		end else begin
			SYNC_CS[3:0]	<= {SYNC_CS[2:0],EEPROM_CS_IN};
			SYNC_SK[2:0]	<= {SYNC_SK[1:0],EEPROM_SK_IN};
			SYNC_SK[3]		<= (SYNC_SK[2:1] == 2'b01);
			SYNC_DI[3:0]	<= {SYNC_DI[2:0],EEPROM_DI_IN};
			CMD_CS		<= SYNC_CS[3];
			CMD_SK[0]	<= SYNC_CS[3] & SYNC_SK[3] & ~(CMD_CNT[3] & CMD_CNT[0]);
			CMD_SK[1]	<= SYNC_CS[3] & SYNC_SK[3] &  (CMD_CNT[3] & CMD_CNT[0]) & ~(DAT_CNT[3] & DAT_CNT[0]);
			CMD_DI		<= SYNC_DI[3];
			STA_BT		<= (
				(CMD_CS & CMD_SK[0] & CMD_DI)|
				(CMD_CS & STA_BT)
			);
			CMD_CNT[3:0]	<= STA_BT?		(CMD_CNT[3:0] + (CMD_SK[0]?		4'd1:	4'd0)):		4'b0000;
			DAT_CNT[3:0]	<= CMD_CS?	(DAT_CNT[3:0] + (CMD_SK[1]?		4'd1:	4'd0)):		4'b0001;
			MEM_CMD[1:0]	<= (CMD_SK[0] & ~(|CMD_CNT[3:1]))?	{MEM_CMD[0],CMD_DI}:		MEM_CMD[1:0];
			MEM_ADR[7:0]	<= CMD_SK[0]?	{MEM_ADR[6:0],CMD_DI}:		MEM_ADR[7:0];
			MEM_SDT[7:0]	<= CMD_SK[1]?	{MEM_SDT[6:0],CMD_DI}:		MEM_SDT[7:0];
			MEM_SET			<= CMD_CS & CMD_SK[1] & DAT_CNT[3] & (MEM_CMD[1:0] == 2'b01) & ~PROTECT;
			MEM_PRO			<= CMD_CS & CMD_SK[0] & CMD_CNT[3] & (MEM_CMD[1:0] == 2'b00);
			PROTECT			<= (
				(~PROTECT &  (MEM_PRO & (MEM_ADR[6:5] == 2'b00)))|
				( PROTECT & ~(MEM_PRO & (MEM_ADR[6:5] == 2'b11)))
			);
			MEM_GET		<= CMD_CS & CMD_SK[0] & CMD_CNT[3];
			MEM_LOD		<= (
				(CMD_CS & CMD_SK[0] & CMD_CNT[3] & (MEM_CMD[1:0] == 2'b10))|
				(CMD_CS & MEM_LOD   & ~CMD_SK[1])
			);
			OUT_SFT[7:0]	<= CMD_SK[1]?	(MEM_LOD?	MEM_GDT[7:0]:	{OUT_SFT[6:0],1'b1}):	(CMD_CS?	OUT_SFT[7:0]:	8'b1111_1111);
			EEPROM_DO_OUT	<= ~MEM_LOD & OUT_SFT[7];
		end
	end

endmodule
`default_nettype wire
