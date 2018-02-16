`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 	   UCD School of Electrical and Electronic Engineering
// Engineer:	   Ronan Burke
// Create Date:    15:36:42 03/01/2016      
// Module Name:    Lock 
// Project Name:   Assignment 4 - Combination Lock Design 
// Target Devices: XC7A100T-csg324 on Digilent Nexys 4 board
// Description: compares the keys pressed by the user to the designated sequence,
// and then sends a signal to unlock if it is correct.
// Dependencies: None.
//
//////////////////////////////////////////////////////////////////////////////////

module lock(
    input clock, // 5 MHz clock
	input reset, // reset
	input newkey,
    input [3:0] keycode,
    output reg [3:0] count,
    output reg [1:0] status
    );

    reg clear;
	reg [3:0] Q1, Q2, Q3, Q4;
	wire [15:0] Q;
	reg [3:0] nextQ1, nextQ2, nextQ3, nextQ4;
	reg [3:0] nextcount;
	reg [1:0] sig; 
	reg sig2;
	reg [1:0] unlock;
	reg timeout;
	reg action;
	reg newkeyafter, nextkeyafter;
	
	localparam code = 16'b0101000101010001;

	//////////////////////////
	////// First digit ///////
	//////////////////////////
	// multiplexer
    always @ (newkey, keycode, Q1, nextQ1, clear)
		if(clear)
		    nextQ1 = 4'b0000;
		else if (newkey==1)
			nextQ1 = keycode;
		else
			nextQ1 = Q1;
	
	// register
	always @ (posedge clock or posedge reset) // all happens on clock edge
		if (reset) Q1 <= 4'b0;
		else Q1 <= nextQ1;
	
	//////////////////////////
	////// Second digit //////
	//////////////////////////
	// multiplexer
	always @ (newkey, keycode, Q2, nextQ2, count, Q1, clear)
		if(clear)
            nextQ2 = 4'b0000;
		else if (newkey==1 && count>0)
			nextQ2 = Q1;
		else
			nextQ2 = Q2;
		
	// register
	always @ (posedge clock or posedge reset) // all happens on clock edge
		if (reset) Q2 <= 4'b0;
		else Q2 <= nextQ2;
				
	//////////////////////////			
	////// Third digit ///////
	//////////////////////////
	// multiplexer
	always @ (newkey, keycode, Q3, nextQ3, count, Q2, clear)
		if(clear)
            nextQ3 = 4'b0000;
		else if (newkey==1 && count>1)
			nextQ3 = Q2;
		else
			nextQ3 = Q3;
		
	// register
	always @ (posedge clock or posedge reset) // all happens on clock edge
		if (reset) Q3 <= 4'b0;
		else Q3 <= nextQ3;
		
	//////////////////////////			
	////// Fourth digit //////
	//////////////////////////
	// multiplexer
	always @ (newkey, keycode, Q, nextQ4, count, Q3, Q4, clear)
		if(clear)
            nextQ4 = 4'b0000;
		else if (newkey==1 && count>2)
			nextQ4 = Q3;
		else
			nextQ4 = Q4;
		
	// register
	always @ (posedge clock or posedge reset) // all happens on clock edge
		if (reset) Q4 <= 4'b0;
		else Q4 <= nextQ4;
	
	//////////////////////////			
    //////// Combine /////////
    //////////////////////////    
    assign Q = {(Q4 - 4'b0001), (Q3 - 4'b0001), (Q2 - 4'b0001), (Q1 - 4'b0001)};
    assign buzzer = 1'b1;	
	
    //////////////////////////			
    ///////// Clear /////////
    //////////////////////////     
    // combinational logic for clear
    always @ (keycode, clear,timeout)
        if ((keycode==4'd11)||(timeout))
            clear = 1'b1;
        else
            clear = 1'b0;        

    //////////////////////////			
    ///////// Unlock /////////
    ////////////////////////// 
	// combinational logic for unlock
	always @ (Q, count, unlock)
        if ((Q==code)&& count == 4)
            unlock = 2'b10;
        else if (Q!=code && count==4)
            unlock = 2'b01;
        else
            unlock = 2'b00;
	
    //////////////////////////			
    ///////// Status /////////
    //////////////////////////    
    // multiplexer
    always @ (unlock, timeout, status, sig)
        if (unlock==2'b10) // correct code when locked
            sig = 2'b10;
        else if (unlock==2'b01) // incorrect code when locked
            sig = 2'b01;
        else if (timeout==1) // time out after correct or incorrect
            sig = 2'b00;
        else
            sig = status;
       
    // register
    always @ (posedge clock or posedge reset) // all happens on clock edge
        if (reset) status <= 2'b0;
        else status <= sig;

    //////////////////////////			
    ///////// Count //////////
    ////////////////////////// 
	// multiplexer 
    always @ (newkey, clear, nextcount, count, action)
        if(action || clear)
            nextcount = 0;
        else if (newkey)
            nextcount = count + 1'b1;
        else
            nextcount = count;
		
	// register
	always @ (posedge clock or posedge reset) // all happens on clock edge
		if (reset) count <= 16'b0;
		else count <= nextcount;

    //////////////////////////			
    ///////// Action /////////
    //////////////////////////    
    // multiplexer
    always @ (unlock, sig2, timeout, newkeyafter, action)
        if ((unlock==2'b10 || unlock==2'b01)&&newkeyafter) // code entered
            sig2 = 1'b1;
        else if (timeout)
            sig2 = 1'b0;
        else
            sig2 = action;
        
    // register
    always @ (posedge clock or posedge reset) // all happens on clock edge
        if (reset) action <= 1'b0;
        else action <= sig2;

    //////////////////////////
	//////// Timeout /////////
	//////////////////////////
	parameter WIDTH = 5'd26;
	parameter CYCLE = 26'd100;
	
	reg [WIDTH-1:0] T, nextT;
    
	// multiplexer to count up or set to zero
	always @ (T, action)
		if (action)
			nextT = T + 1'b1; // count up 1
		else
			nextT = 1'b0; // reset count
        
	// register
	always @ (posedge clock or posedge reset) // all happens on clock edge
		if (reset) T <= 1'b0;
		else T <= nextT;

	// combinational logic to check if the count equals the cycle
	always @ (T)
		if(T == CYCLE) timeout = 1'b1;
		else timeout = 1'b0; 
 
    //////////////////////////
    ////// Newkey After //////
    //////////////////////////
    always @ (newkey)
    if(newkey)
        nextkeyafter = 1'b1;
    else
        nextkeyafter = 1'b0;
    
    // register
    always @ (posedge clock or posedge reset) // all happens on clock edge
        if (reset) newkeyafter <= 1'b0;
        else newkeyafter <= nextkeyafter;
	
endmodule