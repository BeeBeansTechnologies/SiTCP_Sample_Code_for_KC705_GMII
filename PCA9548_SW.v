//----------------------------------------------------------------------//
//
//	Copyright (c) 2017 BeeBeans Technologies All rights reserved
//
//		System		: AC701
//
//		Module		: PCA9548_SW
//
//		Description	: IIC Control with PCA9548
//
//		file		: PCA9548_SW.v
//
//		Note		:
//
//		history	:
//			171003	------		Created by M.Ishiwata
//
//----------------------------------------------------------------------//
`default_nettype none
module
	PCA9548_SW #(
		parameter	[ 6:0]	PCA9548_AD	= 7'b1110_100,	// PCA9548 Dvice Address
		parameter	[ 7:0]	PCA9548_SL	= 8'b0001_1000,	// PCA9548 Select code (Ch3,Ch4 enable)
		parameter	[ 7:0]	FREQUENCY	= 8'd200,		// CLK_IN Frequency  > 10MHz
		parameter	integer	DRIVE		= 4,			// Output Buffer Strength
		parameter			IOSTANDARD	= "DEFAULT",	// I/O Standard
		parameter			SLEW		= "SLOW"		// Outputbufer Slew rate
	)(
		input	wire			CLK_IN,					// System Clock
		input	wire			RESET_IN,				// Reset
		output	reg				INIT_ERR_OUT,			// PCA9548 Initialize Error
		// Ch0
		input	wire			IIC0_REQ_IN,			// IIC ch0 Request
		input	wire	[ 7:0]	IIC0_NUM_IN,			// IIC ch0 Number of Access[7:0]	0x00:1Byte , 0xff:256Byte
		input	wire	[ 6:0]	IIC0_DAD_IN,			// IIC ch0 Device Address[6:0]
		input	wire	[ 7:0]	IIC0_ADR_IN,			// IIC ch0 Word Address[7:0]
		input	wire			IIC0_RNW_IN,			// IIC ch0 Read(1) / Write(0)
		input	wire	[ 7:0]	IIC0_WDT_IN,			// IIC ch0 Write Data[7:0]
		output	reg				IIC0_RAK_OUT,			// IIC ch0 Request Acknowledge
		output	reg		 		IIC0_WDA_OUT,			// IIC ch0 Wite Data Acknowledge(Next Data Request)
		output	reg		 		IIC0_WAE_OUT,			// IIC ch0 Wite Last Data Acknowledge(same as IIC_WDA timing)
		output	reg				IIC0_BSY_OUT,			// IIC ch0 Busy
		output	reg		[ 7:0]	IIC0_RDT_OUT,			// IIC ch0 Read Data[7:0]
		output	reg				IIC0_RVL_OUT,			// IIC ch0 Read Data Valid
		output	reg				IIC0_EOR_OUT,			// IIC ch0 End of Read Data(same as IIC_RVL timing)
		output	reg				IIC0_ERR_OUT,			// IIC ch0 Error Detect
		// Ch1
		input	wire			IIC1_REQ_IN,			// IIC ch1 Request
		input	wire	[ 7:0]	IIC1_NUM_IN,			// IIC ch1 Number of Access[7:0]	0x00:1Byte , 0xff:256Byte
		input	wire	[ 6:0]	IIC1_DAD_IN,			// IIC ch1 Device Address[6:0]
		input	wire	[ 7:0]	IIC1_ADR_IN,			// IIC ch1 Word Address[7:0]
		input	wire			IIC1_RNW_IN,			// IIC ch1 Read(1) / Write(0)
		input	wire	[ 7:0]	IIC1_WDT_IN,			// IIC ch1 Write Data[7:0]
		output	reg				IIC1_RAK_OUT,			// IIC ch1 Request Acknowledge
		output	reg		 		IIC1_WDA_OUT,			// IIC ch1 Wite Data Acknowledge(Next Data Request)
		output	reg		 		IIC1_WAE_OUT,			// IIC ch1 Wite Last Data Acknowledge(same as IIC_WDA timing)
		output	reg				IIC1_BSY_OUT,			// IIC ch1 Busy
		output	reg		[ 7:0]	IIC1_RDT_OUT,			// IIC ch1 Read Data[7:0]
		output	reg				IIC1_RVL_OUT,			// IIC ch1 Read Data Valid
		output	reg				IIC1_EOR_OUT,			// IIC ch1 End of Read Data(same as IIC_RVL timing)
		output	reg				IIC1_ERR_OUT,			// IIC ch1 Error Detect
		// Device Interface
		output	wire			IIC_SCL_OUT,			// IIC Clock
		inout	wire			IIC_SDA_IO				// IIC Data
	);

	reg				INI_EXE;
	reg		[ 7:0]	INI_CNT;
	reg				IIC_REQ;
	reg		[ 1:0]	IIC_SEL;
	reg		[ 7:0]	IIC_NUM;
	reg		[ 6:0]	IIC_DAD;
	reg				IIC_NOA;
	reg		[ 7:0]	IIC_ADR;
	reg				IIC_RNW;
	reg		[ 1:0]	EXE_SEL;
	reg		[ 7:0]	IIC_WDT;

	wire			IIC_RAK;
	wire			IIC_WDA;
	wire			IIC_WAE;
	wire			IIC_BSY;
	wire	[ 7:0]	IIC_RDT;
	wire			IIC_RVL;
	wire			IIC_EOR;
	wire			IIC_ERR;

	always@(posedge CLK_IN or posedge RESET_IN)begin
		if (RESET_IN) begin
			INI_EXE				<= 1;
			INI_CNT[7:0]		<= 8'd0;
			IIC_REQ				<= 0;
			IIC0_BSY_OUT		<= 0;
			IIC1_BSY_OUT		<= 0;
			IIC0_RAK_OUT		<= 0;
			IIC1_RAK_OUT		<= 0;
			IIC_SEL[1:0]		<= 2'b00;
			IIC_NUM[7:0]		<= 8'h00;
			IIC_DAD[6:0]		<= 7'b0000_000;
			IIC_NOA				<= 0;
			IIC_ADR[7:0]		<= 8'h00;
			IIC_RNW				<= 0;
			EXE_SEL[1:0]		<= 2'b00;
			IIC_WDT[7:0]		<= 8'h00;
			IIC0_WDA_OUT		<= 0;
			IIC1_WDA_OUT		<= 0;
			IIC0_WAE_OUT		<= 0;
			IIC1_WAE_OUT		<= 0;
			IIC0_RDT_OUT[7:0]	<= 8'h00;
			IIC1_RDT_OUT[7:0]	<= 8'h00;
			IIC0_RVL_OUT		<= 0;
			IIC1_RVL_OUT		<= 0;
			IIC0_EOR_OUT		<= 0;
			IIC1_EOR_OUT		<= 0;
			IIC0_ERR_OUT		<= 0;
			IIC1_ERR_OUT		<= 0;
			INIT_ERR_OUT		<= 0;
		end else begin
			INI_EXE			<= INI_EXE & ~IIC_REQ;
			INI_CNT[7:0]	<= INI_EXE?	(INI_CNT[7:0] + 8'd1):	8'd0;
			IIC_REQ			<= (
				(~IIC_REQ & INI_CNT[7])|
				(~IIC_REQ & ~INI_EXE & ~IIC0_BSY_OUT & IIC0_REQ_IN)|
				(~IIC_REQ & ~INI_EXE & ~IIC1_BSY_OUT & IIC1_REQ_IN)|
				( IIC_REQ & ~IIC_RAK)
			);
			IIC0_BSY_OUT	<= (~IIC_REQ & ~INI_EXE &  (~IIC0_BSY_OUT & IIC0_REQ_IN)                                )|(IIC_REQ & (IIC_SEL[1:0] == 2'b10))|(IIC_BSY & (EXE_SEL[1:0] == 2'b10));
			IIC1_BSY_OUT	<= (~IIC_REQ & ~INI_EXE & ~(~IIC0_BSY_OUT & IIC0_REQ_IN) & (~IIC1_BSY_OUT & IIC1_REQ_IN))|(IIC_REQ & (IIC_SEL[1:0] == 2'b11))|(IIC_BSY & (EXE_SEL[1:0] == 2'b11));
			IIC0_RAK_OUT	<=  ~IIC_REQ & ~INI_EXE &  (~IIC0_BSY_OUT & IIC0_REQ_IN);
			IIC1_RAK_OUT	<=  ~IIC_REQ & ~INI_EXE & ~(~IIC0_BSY_OUT & IIC0_REQ_IN) & (~IIC1_BSY_OUT & IIC1_REQ_IN);
			IIC_SEL[1:0]	<= (
				(( IIC_REQ                                            )?		IIC_SEL[1:0]:	2'b00)|
				((~IIC_REQ &  INI_EXE                                 )?		2'b01:			2'b00)|
				((~IIC_REQ & ~INI_EXE &  (~IIC0_BSY_OUT & IIC0_REQ_IN))?		2'b10:			2'b00)|
				((~IIC_REQ & ~INI_EXE & ~(~IIC0_BSY_OUT & IIC0_REQ_IN))?		2'b11:			2'b00)
			);
			IIC_NUM[7:0]	<= (
				(( IIC_REQ                                 )?		IIC_NUM[7:0]:		8'h00)|
				((~IIC_REQ &  (~IIC0_BSY_OUT & IIC0_REQ_IN))?		IIC0_NUM_IN[7:0]:	8'h00)|
				((~IIC_REQ & ~(~IIC0_BSY_OUT & IIC0_REQ_IN))?		IIC1_NUM_IN[7:0]:	8'h00)
			);
			IIC_DAD[6:0]	<= (
				(( IIC_REQ                                            )?		IIC_DAD[6:0]:		6'b0000_000)|
				((~IIC_REQ &  INI_EXE                                 )?		PCA9548_AD:			6'b0000_000)|
				((~IIC_REQ & ~INI_EXE &  (~IIC0_BSY_OUT & IIC0_REQ_IN))?		IIC0_DAD_IN[6:0]:	6'b0000_000)|
				((~IIC_REQ & ~INI_EXE & ~(~IIC0_BSY_OUT & IIC0_REQ_IN))?		IIC1_DAD_IN[6:0]:	6'b0000_000)
			);
			IIC_NOA			<= IIC_REQ?		IIC_NOA:	INI_EXE;
			IIC_ADR[7:0]	<= (
				(( IIC_REQ                                 )?		IIC_ADR[7:0]:		8'h00)|
				((~IIC_REQ &  (~IIC0_BSY_OUT & IIC0_REQ_IN))?		IIC0_ADR_IN[7:0]:	8'h00)|
				((~IIC_REQ & ~(~IIC0_BSY_OUT & IIC0_REQ_IN))?		IIC1_ADR_IN[7:0]:	8'h00)
			);
			IIC_RNW		<= (
				(( IIC_REQ                                            )?		IIC_RNW:		1'b0)|
				((~IIC_REQ &  INI_EXE                                 )?		1'b0:			1'b0)|
				((~IIC_REQ & ~INI_EXE &  (~IIC0_BSY_OUT & IIC0_REQ_IN))?		IIC0_RNW_IN:	1'b0)|
				((~IIC_REQ & ~INI_EXE & ~(~IIC0_BSY_OUT & IIC0_REQ_IN))?		IIC1_RNW_IN:	1'b0)
			);
			EXE_SEL[1:0]	<= IIC_BSY?		EXE_SEL[1:0]:		IIC_SEL[1:0];
			IIC_WDT[7:0]	<= (
				((EXE_SEL[1]   == 1'b0 )?		PCA9548_SL:			8'h00)|
				((EXE_SEL[1:0] == 2'b10)?		IIC0_WDT_IN[7:0]:	8'h00)|
				((EXE_SEL[1:0] == 2'b11)?		IIC1_WDT_IN[7:0]:	8'h00)
			);
			IIC0_WDA_OUT	<= (EXE_SEL[1:0] == 2'b10) & IIC_WDA;
			IIC1_WDA_OUT	<= (EXE_SEL[1:0] == 2'b11) & IIC_WDA;
			IIC0_WAE_OUT	<= (EXE_SEL[1:0] == 2'b10) & IIC_WAE;
			IIC1_WAE_OUT	<= (EXE_SEL[1:0] == 2'b11) & IIC_WAE;
			IIC0_RDT_OUT[7:0]	<= ((EXE_SEL[1:0] == 2'b10) & IIC_RVL)?		IIC_RDT[7:0]:	IIC0_RDT_OUT[7:0];
			IIC1_RDT_OUT[7:0]	<= ((EXE_SEL[1:0] == 2'b11) & IIC_RVL)?		IIC_RDT[7:0]:	IIC1_RDT_OUT[7:0];
			IIC0_RVL_OUT	<= (EXE_SEL[1:0] == 2'b10) & IIC_RVL;
			IIC1_RVL_OUT	<= (EXE_SEL[1:0] == 2'b11) & IIC_RVL;
			IIC0_EOR_OUT	<= (EXE_SEL[1:0] == 2'b10) & IIC_EOR;
			IIC1_EOR_OUT	<= (EXE_SEL[1:0] == 2'b11) & IIC_EOR;
			IIC0_ERR_OUT	<= (~INIT_ERR_OUT & (EXE_SEL[1:0] == 2'b10) & IIC_BSY & IIC_ERR)|(~INIT_ERR_OUT & IIC0_ERR_OUT &  IIC0_RAK_OUT);
			IIC1_ERR_OUT	<= (~INIT_ERR_OUT & (EXE_SEL[1:0] == 2'b11) & IIC_BSY & IIC_ERR)|(~INIT_ERR_OUT & IIC1_ERR_OUT & ~IIC1_RAK_OUT);
			INIT_ERR_OUT	<= ((EXE_SEL[1  ] == 1'b0 ) & IIC_BSY & IIC_ERR)|INIT_ERR_OUT;
		end
	end

	IIC_CTL 	#(
		.FREQUENCY		(FREQUENCY),			// CLK_IN Frequency  > 10MHz
		.DRIVE			(DRIVE),				// Output Buffer Strength
		.IOSTANDARD		(IOSTANDARD),			// I/O Standard
		.SLEW			(SLEW)					// Outputbufer Slew rate
	)
	IIC_CTL		(
		.CLK_IN			(CLK_IN),				// System Clock
		.RESET_IN		(RESET_IN),				// Reset

		.IIC_REQ_IN		(IIC_REQ),				// IIC Request
		.IIC_NUM_IN		(IIC_NUM[7:0]),			// IIC Number of Access[7:0]	0x00:1Byte , 0xff:256Byte
		.IIC_DAD_IN		(IIC_DAD[6:0]),			// IIC Device Address[6:0]
		.IIC_NOA_IN		(IIC_NOA),				// IIC No Word Address
		.IIC_ADR_IN		(IIC_ADR[7:0]),			// IIC Word Address[7:0]
		.IIC_RNW_IN		(IIC_RNW),				// IIC Read(1) / Write(0)
		.IIC_WDT_IN		(IIC_WDT[7:0]),			// IIC Write Data[7:0]
		.IIC_RAK_OUT	(IIC_RAK),				// IIC Request Acknowledge
		.IIC_WDA_OUT	(IIC_WDA),				// IIC Wite Data Acknowledge(Next Data Request)
		.IIC_WAE_OUT	(IIC_WAE),				// IIC Wite Last Data Acknowledge(same as IIC_WDA timing)
		.IIC_BSY_OUT	(IIC_BSY),				// IIC Busy
		.IIC_RDT_OUT	(IIC_RDT[7:0]),			// IIC Read Data[7:0]
		.IIC_RVL_OUT	(IIC_RVL),				// IIC Read Data Valid
		.IIC_EOR_OUT	(IIC_EOR),				// IIC End of Read Data(same as IIC_RVL timing)
		.IIC_ERR_OUT	(IIC_ERR),				// IIC Error Detect
		// Device Interface
		.IIC_SCL_OUT	(IIC_SCL_OUT),			// IIC Clock
		.IIC_SDA_IO		(IIC_SDA_IO)			// IIC Data
	);


endmodule
`default_nettype wire
