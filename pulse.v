////////////////////////////////////////////////////////////////////////////////// 
// Engineer:        Eoin O'Connell 
// 
// Create Date:    16:11:33 03/01/2016  
// Module Name:    Pulse 
// 
// Revision 0.4
//
//////////////////////////////////////////////////////////////////////////////////
module pulse(
	input clk,
	input reset,
	output reg pulsig
    );

	parameter WIDTH = 16;
	parameter CYCLE = 16'd65535;
	
	reg [WIDTH-1:0] Q, nextQ;

	// multiplexer to count up or set to zero
	always @ (Q, pulsig)
		if (pulsig)
			nextQ = 1'b0; // reset count
		else
			nextQ = Q + 1'b1; // count up 1

	// register
	always @ (posedge clk or posedge reset) // all happens on clock edge
		if (reset) Q <= 1'b0;
		else Q <= nextQ;

	// combinational logic to check if the count equals the cycle
	always @ (Q)
		if(Q == CYCLE) pulsig = 1'b1;
		else pulsig = 1'b0; 

endmodule
