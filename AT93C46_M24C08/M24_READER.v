
//-------------------------------------------------------------------//
//
//	System      : AT93C46_M24C08
//
//	Module      : M24_READER
//
//	Description : M24 Reader
//
//	file	: M24_READER.v
//
//	Note	:
//
//	history	:
//		1.0.0.0		150629	-----	Created by N.Tanaka
//
//-------------------------------------------------------------------//



module M24_READER(
	M24C08_SCL_OUT,
	M24C08_SDA_OUT,
	M24C08_SDA_IN,
	M24C08_SDAT_OUT,

	RESET_IN,
	SiTCP_RESET_OUT,

	PULSE5uS_IN,
	SYSCLK_IN,

	MEM_WE_OUT,
	MEM_ADDR_OUT,
	MEM_DIN_OUT
);

	output	wire			M24C08_SCL_OUT;
	output	reg				M24C08_SDA_OUT;
	input	wire			M24C08_SDA_IN;
	output	reg				M24C08_SDAT_OUT;

	input	wire			RESET_IN;
	output	wire			SiTCP_RESET_OUT;

	input	wire			PULSE5uS_IN;
	input	wire			SYSCLK_IN;

	output	reg				MEM_WE_OUT;
	output	wire	[6:0]	MEM_ADDR_OUT;
	output	reg		[7:0]	MEM_DIN_OUT;



	reg		[7:0]	ADDRESS;
	reg		[7:0]	COUNT;

	assign	SiTCP_RESET_OUT 	= RESET_IN | ( COUNT[7:2] != 6'd48 );
	assign	MEM_ADDR_OUT[6:0]	= ADDRESS[6:0];
	assign	M24C08_SCL_OUT		= ~COUNT[1];



	always @( posedge SYSCLK_IN or posedge RESET_IN ) begin
		if ( RESET_IN ) begin
			ADDRESS[7:0]	<= 8'd0;
			COUNT[7:0]		<= 8'd0;
			M24C08_SDA_OUT	<= 1'd1;
			M24C08_SDAT_OUT	<= 1'd1;
			MEM_WE_OUT		<= 1'd0;
		end else begin
			COUNT[7:0]		<= ~PULSE5uS_IN ? COUNT[7:0] :
							   ( COUNT[1:0] == 2'd0 ) & ( COUNT[7:2] == 6'd38 ) & ( ADDRESS[7:0] != 8'd127 ) ?
									{6'd29,2'd1} : COUNT[7:0] + ( COUNT[7:2] != 6'd48 );

			M24C08_SDA_OUT	<= ~PULSE5uS_IN ? M24C08_SDA_OUT :
							   ( COUNT[1:0] == 2'd0 ) ? (
									( COUNT[7:2] == 6'd0  ) ? 1'd0 :// START
									( COUNT[7:2] == 6'd19 ) ? 1'd0 :// START
									( COUNT[7:2] == 6'd47 ) ? 1'd1 :// STOP
									M24C08_SDA_OUT ) :
							   
							   ( COUNT[1:0] == 2'd2 ) ? (
									( COUNT[7:2] == 6'd0 ) ? 1'd1 :// Dev select
									( COUNT[7:2] == 6'd1 ) ? 1'd0 :
									( COUNT[7:2] == 6'd2 ) ? 1'd1 :
									( COUNT[7:2] == 6'd3 ) ? 1'd0 :
									( COUNT[7:2] == 6'd4 ) ? 1'd1 :
									( COUNT[7:2] == 6'd5 ) ? 1'd0 :
									( COUNT[7:2] == 6'd6 ) ? 1'd0 :
									( COUNT[7:2] == 6'd7 ) ? 1'd0 :
									// 8: ACK
									( COUNT[7:2] == 6'd9  ) ? 1'd0 :// Address
									( COUNT[7:2] == 6'd10 ) ? 1'd0 :
									( COUNT[7:2] == 6'd11 ) ? 1'd0 :
									( COUNT[7:2] == 6'd12 ) ? 1'd0 :
									( COUNT[7:2] == 6'd13 ) ? 1'd0 :
									( COUNT[7:2] == 6'd14 ) ? 1'd0 :
									( COUNT[7:2] == 6'd15 ) ? 1'd0 :
									( COUNT[7:2] == 6'd16 ) ? 1'd0 :
									// 17: ACK
									( COUNT[7:2] == 6'd18 ) ? 1'd1 :// START
									( COUNT[7:2] == 6'd19 ) ? 1'd1 :// Dev select
									( COUNT[7:2] == 6'd20 ) ? 1'd0 :
									( COUNT[7:2] == 6'd21 ) ? 1'd1 :
									( COUNT[7:2] == 6'd22 ) ? 1'd0 :
									( COUNT[7:2] == 6'd23 ) ? 1'd1 :
									( COUNT[7:2] == 6'd24 ) ? 1'd0 :
									( COUNT[7:2] == 6'd25 ) ? 1'd0 :
									( COUNT[7:2] == 6'd26 ) ? 1'd1 :
									// 27: ACK
									// 28: Read bit 7
									// 29: Read bit 6
									// 30: Read bit 5
									// 31: Read bit 4
									// 32: Read bit 3
									// 33: Read bit 2
									// 34: Read bit 1
									// 35: Read bit 0
									( COUNT[7:2] == 6'd36 ) ? 1'd0 :// ACK
									// 37: Read bit 7
									// 38: Read bit 6
									// 39: Read bit 5
									// 40: Read bit 4
									// 41: Read bit 3
									// 42: Read bit 2
									// 43: Read bit 1
									// 44: Read bit 0
									( COUNT[7:2] == 6'd45 ) ? 1'd1 :// NO ACK
									( COUNT[7:2] == 6'd46 ) ? 1'd0 :// STOP

									M24C08_SDA_OUT ) :
								M24C08_SDA_OUT;

			M24C08_SDAT_OUT	<= ~PULSE5uS_IN ? M24C08_SDAT_OUT :
							   ( COUNT[1:0] == 2'd2 ) ? (
									( COUNT[7:2] == 6'd8  ) ? 1'd0 :
									( COUNT[7:2] == 6'd9  ) ? 1'd1 :
									( COUNT[7:2] == 6'd17 ) ? 1'd0 :
									( COUNT[7:2] == 6'd18 ) ? 1'd1 :
									( COUNT[7:2] == 6'd27 ) ? 1'd0 :
									( COUNT[7:2] == 6'd36 ) ? 1'd1 :
									( COUNT[7:2] == 6'd37 ) ? 1'd0 :
									( COUNT[7:2] == 6'd45 ) ? 1'd1 :

									M24C08_SDAT_OUT ) :
							   M24C08_SDAT_OUT;
			
			MEM_DIN_OUT[7:0]	<= ~PULSE5uS_IN ? MEM_DIN_OUT[7:0]	: ( COUNT[1:0] == 2'b11 ) ? {MEM_DIN_OUT[6:0],M24C08_SDA_IN} : MEM_DIN_OUT[7:0];
			MEM_WE_OUT			<= ~PULSE5uS_IN ? MEM_WE_OUT			: ( COUNT[1:0] == 2'b11 ) & ( ( COUNT[7:2] == 6'd35 ) | ( COUNT[7:2] == 6'd44 ) );
			ADDRESS[7:0]		<= ~PULSE5uS_IN ? ADDRESS[7:0]		: ADDRESS[7:0] + {7'd0,MEM_WE_OUT};
		end
	end

endmodule
