
//-------------------------------------------------------------------//
//
//	System      : PCA9548A (I2C Switcher)
//
//	Module      : PCA9548A
//
//	Note		: This module can set PCA9548A_channel(I2C_switcher)
//				: (attention) This module do not watch ack
//
//	history	:
//		1.0.0		20161125	-----	Created by Tsuyuki
//		2.0.0		20170222	-----	Added parameter
//		3.0.0		20170309	-----	Change Clock
//
//-------------------------------------------------------------------//

module
	PCA9548A #(
		parameter		SYSCLK_FREQ_IN_MHz	= 9'd100,
		parameter		ADDR				= 7'd116,
		parameter		CHANNEL				= 8'b1000
	)(
		input	wire	SYSCLK_IN,			//in 	system clock (200MHz)
		output	reg		I2C_SCLK,			//out 	Serial Clock out
		output	reg		SDO_I2CS,			//out	Serial Data out : SDO (connect to IOBUF(.O))
		input	wire	SDI_I2CS,			//in 	Serial Data in : SDI (conect to IOBUF(.I))
		output	reg		SDT_I2CS,			//out 	toggle inout BUF : SDT (conect to IOBUF(.T))
		input	wire	RESET_IN,			//in 	Reset in
		output	reg 	RESET_OUT			//out 	Reset out
	);

	reg		[7:0]	COUNT;
	reg		[8:0]	CNT1M;
	reg		[1:0]	CNT3;
	reg				INT400K;

	always @( posedge SYSCLK_IN or posedge RESET_IN) begin
		if ( RESET_IN ) begin
			CNT1M[8:0]		<= 9'd0;
			CNT3[1:0]		<= 2'd0;
			INT400K			<= 1'd0;
		end else begin
			CNT1M[8:0]		<= ( CNT1M[8:0] == ( SYSCLK_FREQ_IN_MHz - 9'd1 ) ) ? 9'd0 : CNT1M[8:0] + 9'd1;
			CNT3[1:0]		<= ( CNT1M[8:0] == 9'd0 ) ? ( ( CNT3[1:0] == 2'd2 ) ? 2'd0 : CNT3[1:0] + 2'd1 ) : CNT3[1:0];
			INT400K			<= ( CNT1M[8:0] == 9'd0 ) & ( CNT3[1:0] == 2'd2 );
		end
	end

	always@(posedge SYSCLK_IN or posedge RESET_IN)begin
		if(RESET_IN)begin
			COUNT[7:0]		<= 8'd0;
			I2C_SCLK		<= 1'b1;
			SDT_I2CS		<= 1'b0;
			SDO_I2CS		<= 1'b1;
			RESET_OUT		<= 1'b0;
		end else begin
			if (INT400K) begin
				// Unless switcher returns NACK, better to ignore this phase.
				COUNT[7:0]	<= (COUNT[7:2] < 6'd21)?	COUNT[7:0] + 1'b1:		{6'd22,2'b00};
				I2C_SCLK	<= (COUNT[7:2] < 6'd21)?	COUNT[1]:				1'b1;
				case (COUNT[7:0])
					8'd0:		SDO_I2CS	<= 1'd1;
					8'd1:		SDO_I2CS	<= 1'd1;
					8'd3:		SDO_I2CS	<= 1'd0;		 //start
					8'd5:		SDO_I2CS	<= ADDR[6];
					8'd9:		SDO_I2CS	<= ADDR[5];
					8'd13:		SDO_I2CS	<= ADDR[4];
					8'd17:		SDO_I2CS	<= ADDR[3];
					8'd21: 		SDO_I2CS	<= ADDR[2];
					8'd25:		SDO_I2CS	<= ADDR[1];
					8'd29:		SDO_I2CS	<= ADDR[0];
					8'd33:		SDO_I2CS	<= 1'b0;		// write mode set
				// 37 ACK
					8'd41:		SDO_I2CS	<= CHANNEL[7]; 	// channel select
					8'd45:		SDO_I2CS	<= CHANNEL[6];
					8'd49:		SDO_I2CS	<= CHANNEL[5];
					8'd53:		SDO_I2CS	<= CHANNEL[4];
					8'd57:		SDO_I2CS	<= CHANNEL[3];	// eeprom
					8'd61:		SDO_I2CS	<= CHANNEL[2];
					8'd65:		SDO_I2CS	<= CHANNEL[1];
					8'd69:		SDO_I2CS	<= CHANNEL[0];
				// 73 ACK
					8'd77:		SDO_I2CS	<= 1'b0;
					8'd79:		SDO_I2CS	<= 1'b1;		 // stop
					default:	SDO_I2CS	<= SDO_I2CS;
				endcase
				case (COUNT[7:0])
					8'd37:		SDT_I2CS	<= 1'b1;
					8'd38:		SDT_I2CS	<= 1'b1;
					8'd39:		SDT_I2CS	<= 1'b1;
					8'd40:		SDT_I2CS	<= 1'b1;
					8'd73:		SDT_I2CS	<= 1'b1;
					8'd74:		SDT_I2CS	<= 1'b1;
					8'd75:		SDT_I2CS	<= 1'b1;
					8'd76:		SDT_I2CS	<= 1'b1;
					default:	SDT_I2CS	<= 1'b0;
				endcase
				RESET_OUT	<= ~(COUNT[7:2] < 6'd21);
			end
		end
	end


endmodule
