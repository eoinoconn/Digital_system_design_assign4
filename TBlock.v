`timescale 1ns / 1ns
// Testbench for combination lock module
// Based on example provided

module TBlock;

	// Inputs of the module under test
	reg clock, reset, newkey;
	reg [3:0] keycode; // using 4-bit keycode

	// Outputs from the module under test
	wire [3:0] count;
	wire [1:0] status; // signal for status LEDs
	
    // Define constants for non-numeric keys and console output
    localparam [3:0] CLEAR = 11;
    localparam CONSOLE = 1;
	
	// Testbench internal variables
	integer errorCount = 0;
    integer outFile;
    
	// Instantiate the Unit Under Test (UUT)
	lock uut (
        .clock (clock),
        .reset (reset),
        .keycode (keycode),
        .newkey (newkey),
		.count (count),
		.status (status)
        );

    // Generate the 5 MHz clock signal
	initial begin
		clock = 1'b0; // initialise clock
		#100; // delay at start
		forever
			begin
				#100; // delay 100 ns
				clock = ~clock; // invert the clock
			end
	end
	
    // Define the test sequence
	initial begin
		outFile = $fopen("TBlock_log.txt");	// open log file
		
		reset = 1'b0; // initialize inputs
		keycode = 4'b0;
		newkey = 1'b0;

		#1000; // delay at start     
		reset = 1'b1; // reset pulse of at least one clock cycle
		@(negedge clock); // wait for falling clock edge
		@(negedge clock) reset = 1'b0; // end pulse at second falling edge
		
		#2000; // more delay

        CHECK(6'b000000); // output should all be 0 after reset

		// 1. Test keys stored in variables Q1, Q2, Q3, Q4 and Q
		PRESS(4);
		CHECK(6'b000100); // output should indicate 1 key pressed
		PRESS(5);
		CHECK(6'b001000); // output should indicate 2 keys pressed
		PRESS(6);
        CHECK(6'b001100); // output should indicate 3 keys pressed
		PRESS(7);
		CHECK(6'b000001); // output should indicate 0 keys pressed and status 01
		#30000;
		
		// 2. Test clear resets the values of count to 0
		PRESS(11);          
		CHECK(6'b000000); // output should indicate no keys pressed
		#30000;
        		
		// 3. Test unlock is 10 when Q matches code
		// 4. Test status is 10 when Q matches code
		PRESS(6);
		PRESS(2);
		PRESS(6);
		PRESS(2);
        CHECK(6'b000010); // output should indicate 0 keys pressed and status 10
        #30000;

        // 5. Test status is 10 when correct sequence after clear
        PRESS(11); 
        PRESS(6);
        PRESS(2);
        PRESS(6);
        PRESS(2);
        CHECK(6'b000010); // output should indicate 0 keys pressed and status 10
        #30000;
        
        // 6. Test status is 01 when Q doesn't match code
        PRESS(1);
        PRESS(2);
		PRESS(3);
        PRESS(4);
        CHECK(6'b000001); // output should indicate 0 keys pressed and status 01
        #30000;

        // 7. Test status is 00 when 3 or less keys are pressed
        // 8. Test count increments by 1 when newkey is 1
        PRESS(5);
        PRESS(3);
        PRESS(9);
        CHECK(6'b001100); // output should indicate three keys pressed and status 01
        #30000;
        
        // 9. Test count resets to 0 when count reaches 4
        PRESS(1);
        PRESS(2);
        PRESS(3);
        PRESS(4);
        PRESS(5);
        CHECK(6'b000001); // output should indicate 0 keys pressed and status 01
        #30000;
        
        // 10. Test action is 1 from attempt until timeout elapsed 
        // 11. Test timeout increments until action lasts until cycle limit
        // 12. Test newkeyafter is 1 a clock cycle after newkey
        PRESS(6);
        PRESS(2);
        PRESS(6);
        PRESS(2);  
        CHECK(6'b000010); // output should indicate 0 keys pressed and status 10
        $fclose(outFile);
        $display("Simulation finished with %d errors", errorCount);
		$stop;            // stop the simulation
	end

    // Task to simulate input from keypad
	task PRESS (input [3:0] key); // input is value of key to be simulated
		begin
            @ (posedge clock); // wait for clock edge, as keypad will do
			#1 keycode = key; // set keycode just after clock edge
			@ (posedge clock); // wait for next clock edge
			#1 keycode = {$random}%16;	// random keycode due to bounce
            @ (posedge clock); // just one clock cycle
			#1 keycode = key; // then back to correct keycode
            repeat(3) @ (posedge clock);    // wait a few clock cycles
			#1 newkey = 1'b1; // generate pulse on newkey
			@ (posedge clock);	
			#1 newkey = 1'b0; // pulse lasts one clock cycle
			$fdisplay(outFile, "    time %t ps, key %h", $time, keycode);
			repeat(5)
				@ (posedge clock);// hold keycode for 5 more clock cycles
			#1 keycode = 5'h0; // then remove it
		end
	endtask
	
	// Task to check outputs from lock
    task CHECK (input [5:0] expected); // expected outputs: count, status
        reg [5:0] outbits; // local variable to combine all outputs
        begin
            repeat(5) @ (posedge clock); // wait for short buzz to stop
            #1 outbits = {count, status}; // capture just after clock edge
            if (outbits != expected) // compare with expected
                begin
                    $fdisplay(outFile|CONSOLE, "*** time %t ps, outputs = %b, expected %b", 
                            $time, outbits, expected);
                    errorCount = errorCount + 1;    // increment error counter
                end
                else $fdisplay(outFile, "    time %t ps, outputs = %b", $time, outbits);
        end
    endtask
	
endmodule

