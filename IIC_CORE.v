//----------------------------------------------------------------------//
//
//	Copyright (c) 2017 BeeBeans Technologies All rights reserved
//
//		System		: independent
//
//		Module		: IIC_CORE
//
//		Description	: IIC bus Control Core
//
//		file		: IIC_CORE.v
//
//		Note		:
//			At the time of reading, a write command is required for address setting.
//			In this module, register address and write data are not distinguished.
//
//		history	:
//			170928	------		Created by M.Ishiwata
//
//----------------------------------------------------------------------//
`default_nettype none
module
	IIC_CORE #(
		parameter	[ 7:0]	FREQUENCY	= 8'd200,		// CLK_IN Frequency  > 10MHz
		parameter	integer	DRIVE		= 4,			// Output Buffer Strength
		parameter			IOSTANDARD	= "DEFAULT",	// I/O Standard
		parameter			SLEW		= "SLOW"		// Outputbufer Slew rate
	)(
		input	wire			CLK_IN,					// System Clock
		input	wire			RESET_IN,				// Reset
		input	wire			IIC_REQ_IN,				// IIC Request
		input	wire			IIC_AST_IN,				// IIC Address Set Request
		input	wire	[ 7:0]	IIC_NUM_IN,				// IIC Number of Access[7:0]	0x00:1Byte/2Byte , 0xff:256Byte/257Byte (Read / Write)
		input	wire	[ 6:0]	IIC_DAD_IN,				// IIC Device Address[6:0]
		input	wire			IIC_RNW_IN,				// IIC Read(1) / Write(0)
		input	wire	[ 7:0]	IIC_WDT_IN,				// IIC Write Data[7:0]
		output	reg				IIC_RAK_OUT,			// IIC Request Acknowledge
		output	reg		 		IIC_WDA_OUT,			// IIC Wite Data Acknowledge(Next Data Request)
		output	reg				IIC_WAE_OUT,			// IIC Wite Last Data Acknowledge(same as IIC_WDA timing)
		output	reg				IIC_BSY_OUT,			// IIC Busy
		output	reg		[ 7:0]	IIC_RDT_OUT,			// IIC Read Data[7:0]
		output	reg				IIC_RVL_OUT,			// IIC Read Data Valid
		output	reg				IIC_EOR_OUT,			// IIC End of Read Data(same as IIC_RVL timing)
		output	reg				IIC_ERR_OUT,			// IIC Error Detect
		// Device Interface
		output	wire			IIC_SCL_OUT,			// IIC Clock
		inout	wire			IIC_SDA_IO				// IIC Data
	);


	reg		[ 8:0]	CNT_1US;

	reg		[ 2:0]	CNT_CKE;
	reg				ENB_SCL;
	reg				ENB_SDA;
	reg				OR_SCL;
	reg				ACK_BUF;
	reg				ERR_DET;
	reg				IIC_EXECUTE;
	reg				EXE_READ;
	wire			OR_SDA;
	reg		[ 8:0]	SFT_DAT;
	reg		[ 4:0]	BIT_CNT;
	reg		[ 8:0]	DAT_CNT;
	reg				IIC_STOP;
	reg				IIC_END;

	wire			OB_SCL;
	wire			OB_SDA;
	wire			IB_SDA;
	wire			IR_SDA;


// SPI Timing
	always@(posedge CLK_IN or posedge RESET_IN)begin
		if (RESET_IN) begin
			CNT_1US[8:0]	<= 5'd0;
		end else begin
			CNT_1US[8:0]	<= CNT_1US[8]?		(FREQUENCY - 2):		(CNT_1US[8:0] - 9'd1);
		end
	end


// Requset Control

	assign		OR_SDA	= ~IIC_STOP & SFT_DAT[8] & ~(BIT_CNT[4] & BIT_CNT[3] & ~DAT_CNT[8] & ~IIC_ERR_OUT & EXE_READ);
	always@(posedge CLK_IN or posedge RESET_IN)begin
		if (RESET_IN) begin
			CNT_CKE[2:0]		<= 3'b011;
			ENB_SCL				<= 1'b0;
			ENB_SDA				<= 1'b0;
			OR_SCL				<= 1'b1;
			ACK_BUF				<= 1'b0;
			IIC_RDT_OUT[7:0]	<= 8'h00;
			ERR_DET				<= 1'b0;
			IIC_BSY_OUT			<= 1'b0;
			IIC_EXECUTE			<= 1'b0;
			EXE_READ			<= 1'b0;
			SFT_DAT[8:0]		<= 9'b1_1111_1111;
			BIT_CNT[4:0]		<= 5'b0_0000;
			DAT_CNT[8:0]		<= 9'd0;
			IIC_STOP			<= 0;
			IIC_END				<= 0;
			IIC_RAK_OUT			<= 1'b0;
			IIC_WDA_OUT			<= 1'b0;
			IIC_WAE_OUT			<= 1'b0;
			IIC_RVL_OUT			<= 1'b0;
			IIC_EOR_OUT			<= 1'b0;
			IIC_ERR_OUT			<= 1'b0;
		end else begin
			if (CNT_1US[8]) begin
				CNT_CKE[2:0]	<= (CNT_CKE[2] & ~(CNT_CKE[0] & OR_SCL))?		4'b011:		(CNT_CKE[2:0] - 3'd1);
			end
			ENB_SCL	<= CNT_1US[8] & CNT_CKE[2] &  CNT_CKE[0] & ~(OR_SCL & ~IIC_BSY_OUT);
			ENB_SDA	<= CNT_1US[8] & CNT_CKE[2] & ~CNT_CKE[0];
			
			if (ENB_SCL) begin
				OR_SCL				<= ~(OR_SCL & IIC_BSY_OUT & ~IIC_STOP & ~IIC_END);
				ACK_BUF				<= IR_SDA;
				IIC_RDT_OUT[7:0]	<= OR_SCL?	IIC_RDT_OUT[7:0]:	{IIC_RDT_OUT[6:0],ACK_BUF};
				ERR_DET				<= ~OR_SCL & BIT_CNT[3] & ~(BIT_CNT[4] & EXE_READ) & IR_SDA;
			end

			if (ENB_SDA) begin
				IIC_BSY_OUT		<= (
					(~IIC_BSY_OUT & IIC_REQ_IN)|
					( IIC_BSY_OUT & ~IIC_END)
				);
				IIC_EXECUTE		<= IIC_BSY_OUT & ~IIC_END;
				EXE_READ	<= IIC_BSY_OUT?		EXE_READ:		IIC_RNW_IN;
				SFT_DAT[8:0]	<= (
					(IIC_STOP?		9'b1_0000_0000:		9'b0_0000_0000)|
					(
						((~IIC_EXECUTE & ~IIC_BSY_OUT           )?		{~IIC_REQ_IN,IIC_DAD_IN[6:0],IIC_RNW_IN}:	9'b0000_0000_0)|
						((~IIC_EXECUTE &  IIC_BSY_OUT           )?		{SFT_DAT[7:0],1'b1}:						9'b0000_0000_0)|
						(( IIC_EXECUTE & ~BIT_CNT[3]            )?		{SFT_DAT[7:0],1'b1}:						9'b0000_0000_0)|
						(( IIC_EXECUTE &  BIT_CNT[3] & ~EXE_READ)?		{IIC_WDT_IN[7:0],1'b1}:						9'b0000_0000_0)|
						(( IIC_EXECUTE &  BIT_CNT[3] &  EXE_READ)?		{8'hff,1'b1}:								9'b0000_0000_0)
					)
				);
				BIT_CNT[4]		<= IIC_EXECUTE & (BIT_CNT[3]|BIT_CNT[4]);
				BIT_CNT[3:0]	<= IIC_EXECUTE?		(BIT_CNT[3:0] + (BIT_CNT[3]?	4'b1000:	4'b0001)):		4'b0000;
				DAT_CNT[8:0]	<= IIC_BSY_OUT?		(DAT_CNT[8:0] - (BIT_CNT[3]?	9'd1:		9'd0)):			{1'b0,(IIC_AST_IN?	9'b1_1111_1111:		IIC_NUM_IN[7:0])};
				IIC_STOP		<= BIT_CNT[3] & (IIC_ERR_OUT|(EXE_READ?	DAT_CNT[8]:		(DAT_CNT[8] & ~DAT_CNT[0])));
				IIC_END			<= IIC_STOP;
			end
			IIC_RAK_OUT	<= ENB_SDA & ~IIC_BSY_OUT & IIC_REQ_IN;
			IIC_WDA_OUT	<= ENB_SDA & ~EXE_READ & BIT_CNT[3] & ~IIC_ERR_OUT & ~(DAT_CNT[8] & ~DAT_CNT[0]);
			IIC_WAE_OUT	<= ENB_SDA & ~EXE_READ & BIT_CNT[3] & ~IIC_ERR_OUT & DAT_CNT[8] & DAT_CNT[0];
			IIC_RVL_OUT	<= ENB_SDA &  EXE_READ & BIT_CNT[4] & BIT_CNT[3];
			IIC_EOR_OUT	<= ENB_SDA &  EXE_READ & BIT_CNT[4] & BIT_CNT[3] & DAT_CNT[8];
			IIC_ERR_OUT	<= ~(ENB_SDA & ~IIC_BSY_OUT & IIC_REQ_IN) & (IIC_ERR_OUT | ERR_DET);
		end
	end

	(* IOB = "TRUE" *)	FD	#(.INIT(1'b1))							IIC_SCL_FD	(.Q(OB_SCL),	.C(CLK_IN),		.D(OR_SCL));
	OBUF	#(.DRIVE(DRIVE), .IOSTANDARD(IOSTANDARD), .SLEW(SLEW))	IIC_SCL_OB	(				.O (IIC_SCL_OUT),	.I(OB_SCL));
	(* IOB = "TRUE" *)	FD	#(.INIT(1'b1))							IIC_SDA_OF	(.Q(OB_SDA),	.C(CLK_IN),		.D(OR_SDA));
	IOBUF	#(.DRIVE(DRIVE), .IOSTANDARD(IOSTANDARD), .SLEW(SLEW))	IIC_SDA_OB	(.O(IB_SDA),	.IO(IIC_SDA_IO),	.I(1'b0),	.T(OB_SDA));
	PULLUP															IIC_SDA_PU	(               .O (IIC_SDA_IO));
	(* IOB = "TRUE" *)	FD	#(.INIT(1'b1))							IIC_SDA_IF	(.Q(IR_SDA),	.C(CLK_IN),		.D(IB_SDA));

endmodule
`default_nettype wire
