//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Eoin O'Connell
// Target Device: XC7A100T-csg324 on Digilent Nexys 4 board
// Description:   Top-level module for combination lock design.
//                Defines top-level input and output signals.
//                Instantiates clock and reset generator block, for 5 MHz clock
//                Instantiates other modules to implement combination lock...
//  Created: 26 April 2016
//////////////////////////////////////////////////////////////////////////////////
module CombinationLockTop(
        input clk100,		 // 100 MHz clock from oscillator on board
        input rstPBn,		 // reset signal, active low, from CPU RESET pushbutton
        input [5:0] kpcol,   // keypad column signals
        output [3:0] kprow,  // keypad row signals
        output unlock,  	// 1 to unlock the mechanical lock
		output [2:0] led,	// signals to drive LEDs for status indication
		output [1:0] RGB1
        );

// ===========================================================================
// Interconnecting Signals
    wire clk5;              // 5 MHz clock signal, buffered
    wire reset;             // internal reset signal, active high
    wire newkey       // pulse to indicate new key pressed, keycode valid
    wire [3:0] keycode;     // 5-bit code to identify key pressed
    wire fail;
    wire [3:0] key_count;
    wire [1:0] status;
// ===========================================================================
// Instantiate clock and reset generator, connect to signals
    clockReset  clkGen  (
         .clk100 (clk100),
         .rstPBn (rstPBn),
         .clk5   (clk5),
         .reset  (reset) );

//==================================================================================
// Keypad interface to scan keypad and return valid keycodes
    keypad keypad (
        .clk(clk5),			// clock for keypad module is 5 MHz
        .reset(reset),		// reset is internal reset signal
        .kpcol(kpcol),		// 6 keypad column inputs
        .kprow(kprow),		// 4 keypad row outputs
        .new_key(newkey),	// new key signal
        .key_code(keycode)	// 5-bit code representing key
        );

//==================================================================================
// Combination Lock logic
     lock comblock (
        .clock (clk5),
        .reset (reset),
        .keycode (keycode),
        .status (status),
        .count (key_count),
        .newkey(newkey)
        );
		  
	assign unlock = status[1];

//==================================================================================
 //Display interface to indicate lock status
    Display Display (
        .clk(clk5),
        .reset(reset),
        .status(status),
        .count(key_count),
        .leds(led),
        .tri_colour(RGB1)
        );
        
  
//==================================================================================	
endmodule
