
module
	RBCP(
		input	wire			CLK,	
		input	wire	[ 2:0]	DIP,		
		input	wire			RBCP_WE,	
		input	wire			RBCP_RE,	
		input	wire	[ 7:0]	RBCP_WD,	
		input	wire	[31:0]	RBCP_ADDR,	
		output	reg		[ 7:0]	RBCP_RD,	
		output	reg				RBCP_ACK	
	);

	reg		[ 7:0]	x00Reg;
	reg		[ 7:0]	x01Reg;
	reg		[ 7:0]	x02Reg;
	reg		[ 7:0]	x03Reg;
	reg				P0WE;
	reg				P0RE;
	reg				P1WE;
	reg				P1RE;
	reg		[ 7:0]	P0_WD;
	reg		[ 7:0]	P1_WD;
	reg		[ 1:0]	P0_ADDR_HI;	// Indicates that RBCP_ADDR[31:16] and RBCP_ADDR[15:2] are 0
	reg		[ 1:0]	P1_ADDR_HI;
	reg		[ 1:0]	P0_ADDR_LO;	// RBCP_ADDR lower 2 bits
	reg				REG00_SEL;
	reg				REG01_SEL;
	reg				REG02_SEL;
	reg				REG03_SEL;

	always@(posedge CLK)begin
		// 1st
		P0WE			<= RBCP_WE;
		P0RE			<= RBCP_RE;
		P0_WD[7:0]		<= RBCP_WD[7:0];
		P0_ADDR_HI[1]	<= (RBCP_ADDR[31:16] == 16'd0);
		P0_ADDR_HI[0]	<= (RBCP_ADDR[15: 2] == 14'd0);
		P0_ADDR_LO[1:0]	<= RBCP_ADDR[1:0];
		// 2nd
		P1WE			<= P0WE;
		P1RE			<= P0RE;
		P1_WD[7:0]		<= P0_WD[7:0];
		P1_ADDR_HI[1:0]	<= P0_ADDR_HI[1:0];
		REG00_SEL		<= (&P0_ADDR_HI[1:0]) & (P0_ADDR_LO[1:0] == 2'b00);
		REG01_SEL		<= (&P0_ADDR_HI[1:0]) & (P0_ADDR_LO[1:0] == 2'b01);
		REG02_SEL		<= (&P0_ADDR_HI[1:0]) & (P0_ADDR_LO[1:0] == 2'b10);
		REG03_SEL		<= (&P0_ADDR_HI[1:0]) & (P0_ADDR_LO[1:0] == 2'b11);
		// 3rd
			// Write value to register
		x00Reg[7:0]	<=	{5'd0,DIP[2:0]}; // read DIPswitch
		x01Reg[7:0]	<=	P1WE & REG01_SEL?	P1_WD[7:0]:	x01Reg[7:0];
		x02Reg[7:0]	<=	P1WE & REG02_SEL?	P1_WD[7:0]:	x02Reg[7:0];
		x03Reg[7:0]	<=	P1WE & REG03_SEL?	P1_WD[7:0]:	x03Reg[7:0];
			// Read value from register
		RBCP_RD[ 7:0] 	<=	(
			((P1RE & REG00_SEL)?	x00Reg[7:0]:	8'h00)|
			((P1RE & REG01_SEL)?	x01Reg[7:0]:	8'h00)|
			((P1RE & REG02_SEL)?	x02Reg[7:0]:	8'h00)|
			((P1RE & REG03_SEL)?	x03Reg[7:0]:	8'h00)
		);
		// ACK reply
		RBCP_ACK  	<= 	(&P1_ADDR_HI[1:0]) & (P1WE | P1RE);
	end

endmodule


