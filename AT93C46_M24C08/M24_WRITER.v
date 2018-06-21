
//-------------------------------------------------------------------//
//
//	System      : AT93C46_M24C08
//
//	Module      : M24_WRITER
//
//	Description : M24 Writer
//
//	file	: M24_WRITER.v
//
//	Note	:
//
//	history	:
//		1.0.0.0		150629	-----	Created by N.Tanaka
//
//-------------------------------------------------------------------//



module M24_WRITER(
	M24C08_SCL_OUT,
	M24C08_SDA_OUT,
	M24C08_SDA_IN,
	M24C08_SDAT_OUT,

	RESET_IN,

	PULSE5uS_IN,
	SYSCLK_IN,

	ROM_WE_IN,
	ROM_ADDR_IN,
	ROM_DATA_IN
);

	output	wire			M24C08_SCL_OUT;
	output	reg				M24C08_SDA_OUT;
	input	wire			M24C08_SDA_IN;
	output	reg				M24C08_SDAT_OUT;

	input	wire			RESET_IN;

	input	wire			PULSE5uS_IN;
	input	wire			SYSCLK_IN;

	input	wire			ROM_WE_IN;
	input	wire	[6:0]	ROM_ADDR_IN;
	input	wire	[7:0]	ROM_DATA_IN;



	reg		[6:0]	MEM_ADDRA;
	reg		[6:0]	MEM_ADDRB;
	wire	[14:0]	MEM_DOUTB;

	blk_mem_128x15 BUFFER(
		.clka		(SYSCLK_IN			),
		.wea		(ROM_WE_IN			),
		.addra		(MEM_ADDRA[6:0]		),
		.dina		({ROM_ADDR_IN[6:0],ROM_DATA_IN[7:0]}	),
		.clkb		(SYSCLK_IN			),
		.addrb		(MEM_ADDRB[6:0]		),
		.doutb		(MEM_DOUTB[14:0]	)
	);
	always @( posedge SYSCLK_IN or posedge RESET_IN ) begin
		if ( RESET_IN ) begin
			MEM_ADDRA[6:0]	<= 7'd0;
		end else begin
			MEM_ADDRA[6:0]	<= ROM_WE_IN ? MEM_ADDRA[6:0] + 7'd1 : MEM_ADDRA[6:0];
		end
	end



	reg		[11:0]	COUNT;

	assign	M24C08_SCL_OUT		= ~COUNT[1] | ( COUNT[11:2] >= 10'd28 );



	always @( posedge SYSCLK_IN or posedge RESET_IN ) begin
		if ( RESET_IN ) begin
			MEM_ADDRB[6:0]	<= 7'd0;
			COUNT[11:0]		<= {10'd30,2'd0};
			M24C08_SDA_OUT	<= 1'd1;
			M24C08_SDAT_OUT	<= 1'd1;
		end else begin
			COUNT[11:0]		<= ~PULSE5uS_IN ? COUNT[11:0] :
							   ( COUNT[11:2] == 10'h3ff ) & ( MEM_ADDRA[6:0] == MEM_ADDRB[6:0] ) ? COUNT[11:0] :
							   ( COUNT[11:2] == 10'h3ff ) & ( MEM_ADDRA[6:0] != MEM_ADDRB[6:0] ) ? 12'd0 :
							   COUNT[11:0] + 12'd1;
							   
			MEM_ADDRB[6:0]	<= ~PULSE5uS_IN ? MEM_ADDRB[6:0] :
							   ( COUNT[11:2] == 10'd29 ) & ( COUNT[1:0] == 2'd0 ) ? MEM_ADDRB[6:0] + 7'd1 : MEM_ADDRB[6:0];
			M24C08_SDA_OUT	<= ~PULSE5uS_IN ? M24C08_SDA_OUT :
							   ( COUNT[1:0] == 2'd0 ) ? (
									( COUNT[11:2] == 10'd0  ) ? 1'd0 :// START
									( COUNT[11:2] == 10'd28 ) ? 1'd1 :
									M24C08_SDA_OUT ) :
									
							   ( COUNT[1:0] == 2'd2 ) ? (
									( COUNT[11:2] == 10'd0 ) ? 1'd1 :// Dev select
									( COUNT[11:2] == 10'd1 ) ? 1'd0 :
									( COUNT[11:2] == 10'd2 ) ? 1'd1 :
									( COUNT[11:2] == 10'd3 ) ? 1'd0 :
									( COUNT[11:2] == 10'd4 ) ? 1'd1 :
									( COUNT[11:2] == 10'd5 ) ? 1'd0 :
									( COUNT[11:2] == 10'd6 ) ? 1'd0 :
									( COUNT[11:2] == 10'd7 ) ? 1'd0 :
									// 8: ACK
									( COUNT[11:2] == 10'd9  ) ? 1'd0 :// Address
									( COUNT[11:2] == 10'd10 ) ? MEM_DOUTB[14] :
									( COUNT[11:2] == 10'd11 ) ? MEM_DOUTB[13] :
									( COUNT[11:2] == 10'd12 ) ? MEM_DOUTB[12] :
									( COUNT[11:2] == 10'd13 ) ? MEM_DOUTB[11] :
									( COUNT[11:2] == 10'd14 ) ? MEM_DOUTB[10] :
									( COUNT[11:2] == 10'd15 ) ? MEM_DOUTB[9] :
									( COUNT[11:2] == 10'd16 ) ? MEM_DOUTB[8] :
									// 17: ACK
									( COUNT[11:2] == 10'd18 ) ? MEM_DOUTB[7] :// Data
									( COUNT[11:2] == 10'd19 ) ? MEM_DOUTB[6] :
									( COUNT[11:2] == 10'd20 ) ? MEM_DOUTB[5] :
									( COUNT[11:2] == 10'd21 ) ? MEM_DOUTB[4] :
									( COUNT[11:2] == 10'd22 ) ? MEM_DOUTB[3] :
									( COUNT[11:2] == 10'd23 ) ? MEM_DOUTB[2] :
									( COUNT[11:2] == 10'd24 ) ? MEM_DOUTB[1] :
									( COUNT[11:2] == 10'd25 ) ? MEM_DOUTB[0] :
									// 26: ACK
									( COUNT[11:2] == 10'd27 ) ? 1'd0 :// Stop
									M24C08_SDA_OUT ) :
							   M24C08_SDA_OUT;
			M24C08_SDAT_OUT	<= ~PULSE5uS_IN ? M24C08_SDAT_OUT :
							   ( COUNT[1:0] == 2'd2 ) ? (
									( COUNT[11:2] == 10'd8  ) ? 1'd0 :
									( COUNT[11:2] == 10'd9  ) ? 1'd1 :
									( COUNT[11:2] == 10'd17 ) ? 1'd0 :
									( COUNT[11:2] == 10'd18 ) ? 1'd1 :
									( COUNT[11:2] == 10'd26 ) ? 1'd0 :
									( COUNT[11:2] == 10'd27 ) ? 1'd1 :
									M24C08_SDAT_OUT ) :
							   M24C08_SDAT_OUT;

		end
	end

endmodule
