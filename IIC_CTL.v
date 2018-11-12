//----------------------------------------------------------------------//
//
//	Copyright (c) 2017 BeeBeans Technologies All rights reserved
//
//		System		: independent
//
//		Module		: IIC_CTL
//
//		Description	: IIC bus Control
//
//		file		: IIC_CTL.v
//
//		Note		: data format
//								7bit Dvice Address
//								1bit Read/Write
//								8bit Address
//						(N+1) *	8bit Data
//
//		history	:
//			170928	------		Created by M.Ishiwata
//
//----------------------------------------------------------------------//
`default_nettype none
module
	IIC_CTL #(
		parameter	[ 7:0]	FREQUENCY	= 8'd200,		// CLK_IN Frequency  > 10MHz
		parameter	integer	DRIVE		= 4,			// Output Buffer Strength
		parameter			IOSTANDARD	= "DEFAULT",	// I/O Standard
		parameter			SLEW		= "SLOW"		// Outputbufer Slew rate
	)(
		input	wire			CLK_IN,					// System Clock
		input	wire			RESET_IN,				// Reset

		input	wire			IIC_REQ_IN,				// IIC Request
		input	wire	[ 7:0]	IIC_NUM_IN,				// IIC Number of Access[7:0]	0x00:1Byte , 0xff:256Byte
		input	wire	[ 6:0]	IIC_DAD_IN,				// IIC Device Address[6:0]
		input	wire			IIC_NOA_IN,				// IIC No Word Address
		input	wire	[ 7:0]	IIC_ADR_IN,				// IIC Word Address[7:0]
		input	wire			IIC_RNW_IN,				// IIC Read(1) / Write(0)
		input	wire	[ 7:0]	IIC_WDT_IN,				// IIC Write Data[7:0]
		output	reg				IIC_RAK_OUT,			// IIC Request Acknowledge
		output	reg		 		IIC_WDA_OUT,			// IIC Wite Data Acknowledge(Next Data Request)
		output	reg				IIC_WAE_OUT,			// IIC Wite Last Data Acknowledge(same as IIC_WDA timing)
		output	reg				IIC_BSY_OUT,			// IIC Busy
		output	wire	[ 7:0]	IIC_RDT_OUT,			// IIC Read Data[7:0]
		output	wire			IIC_RVL_OUT,			// IIC Read Data Valid
		output	wire			IIC_EOR_OUT,			// IIC End of Read Data(same as IIC_RVL timing)
		output	reg				IIC_ERR_OUT,			// IIC Error Detect
		// Device Interface
		output	wire			IIC_SCL_OUT,			// IIC Clock
		inout	wire			IIC_SDA_IO				// IIC Data
	);

	reg				IIC_READ_PEND;
	reg				CORE_REQ;
	reg				CORE_AST;
	reg		[ 7:0]	CORE_NUM;
	reg		[ 6:0]	CORE_DAD;
	reg				CORE_RNW;
	reg				LOCK_WDT;
	reg		[ 7:0]	CORE_WDT;

	wire			CORE_RAK;
	wire			CORE_WDA;
	wire			CORE_WAE;
	wire			CORE_BSY;
	wire			CORE_ERR;

// Requset Control
	always@(posedge CLK_IN or posedge RESET_IN)begin
		if (RESET_IN) begin
			IIC_BSY_OUT		<= 1'b0;
			IIC_READ_PEND	<= 1'b0;
			IIC_RAK_OUT		<= 1'b0;
			CORE_REQ		<= 1'b0;
			IIC_ERR_OUT		<= 1'b0;
		end else begin
			IIC_BSY_OUT		<= (
				(~IIC_BSY_OUT & ~CORE_BSY & IIC_REQ_IN)|
				( IIC_BSY_OUT & CORE_REQ)|
				( IIC_BSY_OUT & IIC_READ_PEND)|
				( IIC_BSY_OUT & CORE_BSY)
			);
			IIC_READ_PEND	<= (
				(~IIC_BSY_OUT & ~CORE_BSY & IIC_REQ_IN & IIC_RNW_IN & ~IIC_NOA_IN)|
				( IIC_BSY_OUT & IIC_READ_PEND & CORE_REQ)|
				( IIC_BSY_OUT & IIC_READ_PEND & CORE_BSY)
			);
			IIC_RAK_OUT	<= ~IIC_BSY_OUT & ~CORE_BSY & IIC_REQ_IN;
			CORE_REQ	<=  (
				(~IIC_BSY_OUT & ~CORE_BSY & IIC_REQ_IN)|
				( IIC_BSY_OUT & ~CORE_REQ & ~CORE_BSY & IIC_READ_PEND & ~CORE_ERR)|
				( CORE_REQ & ~CORE_RAK)
			);
			IIC_ERR_OUT	<= (CORE_ERR & CORE_BSY)|(CORE_ERR & ~CORE_REQ & ~(~IIC_BSY_OUT & ~CORE_BSY & IIC_REQ_IN));
		end
	end
	
	always@(posedge CLK_IN)begin
		CORE_AST		<= (
			(~CORE_REQ & ~IIC_BSY_OUT &  IIC_RNW_IN & ~IIC_NOA_IN)|
			(~CORE_REQ & ~IIC_BSY_OUT & ~IIC_RNW_IN &  IIC_NOA_IN)|
			( CORE_REQ & CORE_AST)
		);
		CORE_NUM[ 7:0]	<= IIC_BSY_OUT?		CORE_NUM[7:0]:		(IIC_NOA_IN?	8'h00:	IIC_NUM_IN[7:0]);
		CORE_DAD[6:0]	<= IIC_BSY_OUT?		CORE_DAD[6:0]:		IIC_DAD_IN[6:0];
		CORE_RNW		<= (
			(~CORE_REQ & ~IIC_BSY_OUT & IIC_RNW_IN & IIC_NOA_IN)|
			(~CORE_REQ &  IIC_BSY_OUT & IIC_READ_PEND)|
			( CORE_REQ & CORE_RNW)
		);
		LOCK_WDT		<= (
			(~IIC_BSY_OUT & ~CORE_BSY & IIC_REQ_IN & ~IIC_NOA_IN)|
			( IIC_BSY_OUT & LOCK_WDT & ~CORE_WDA)
		);
		CORE_WDT[ 7:0]	<= (
			((~IIC_BSY_OUT            )?		IIC_ADR_IN[7:0]:	8'h00)|
			(( IIC_BSY_OUT & ~LOCK_WDT)?		IIC_WDT_IN[7:0]:	8'h00)|
			(( IIC_BSY_OUT &  LOCK_WDT)?		CORE_WDT[ 7:0]:		8'h00)
		);
		IIC_WDA_OUT		<= CORE_WDA & ~LOCK_WDT;
		IIC_WAE_OUT		<= CORE_WAE;
	end

	IIC_CORE #(
		.FREQUENCY				(FREQUENCY),			// CLK_IN Frequency  > 10MHz
		.DRIVE					(DRIVE),				// Output Buffer Strength
		.IOSTANDARD				(IOSTANDARD),			// I/O Standard
		.SLEW					(SLEW)					// Outputbufer Slew rate
	)
	IIC_CORE(
		.CLK_IN					(CLK_IN),				// System Clock
		.RESET_IN				(RESET_IN),				// Reset
		.IIC_REQ_IN				(CORE_REQ),				// IIC Request
		.IIC_AST_IN				(CORE_AST),				// IIC Address Set Request
		.IIC_NUM_IN				(CORE_NUM[7:0]),		// IIC Number of Access[7:0]	0x00:1Byte/2Byte , 0xff:256Byte/257Byte (Read / Write)
		.IIC_DAD_IN				(CORE_DAD[6:0]),		// IIC Device Address[6:0]
		.IIC_RNW_IN				(CORE_RNW),				// IIC Read(1) / Write(0)
		.IIC_WDT_IN				(CORE_WDT[7:0]),		// IIC Write Data[7:0]
		.IIC_RAK_OUT			(CORE_RAK),				// IIC Request Acknowledge
		.IIC_WDA_OUT			(CORE_WDA),				// IIC Wite Data Acknowledge(Next Data Request)
		.IIC_WAE_OUT			(CORE_WAE),				// IIC Wite Last Data Acknowledge(same as IIC_WDA timing)
		.IIC_BSY_OUT			(CORE_BSY),				// IIC Busy
		.IIC_RDT_OUT			(IIC_RDT_OUT[7:0]),		// IIC Read Data[7:0]
		.IIC_RVL_OUT			(IIC_RVL_OUT),			// IIC Read Data Valid
		.IIC_EOR_OUT			(IIC_EOR_OUT),			// IIC End of Read Data(same as IIC_RVL timing)
		.IIC_ERR_OUT			(CORE_ERR),				// IIC Error Detect
		// Device Interface
		.IIC_SCL_OUT			(IIC_SCL_OUT),			// IIC Clock
		.IIC_SDA_IO				(IIC_SDA_IO)			// IIC Data
	);


endmodule
`default_nettype wire
