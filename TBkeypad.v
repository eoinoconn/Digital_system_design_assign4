`timescale 1us / 100ns
// Testbench for keypad module
// Simulates operation of keypad

module TBkeypad;

	// Inputs of the module under test
	reg clk;
	reg rst;
	reg [5:0] kpcol;

	// Outputs from the module under test
	wire [3:0] kprow;
	wire newkey;
	wire [3:0] keycode;
	
	// Internal signals for the testbench
	integer pressCol, pressRow;  // values for row and column
	reg sawnewkey;				// changes state when newkey detected
	reg [4:0] keyCapture;	// captures keycode when newkey detected
	
	// Instantiate the Unit Under Test (UUT)
	keypad uut (
		.clk(clk), 
		.reset(rst), 
		.kpcol(kpcol), 
		.kprow(kprow), 
		.new_key(newkey), 
		.key_code(keycode)
	);

// This initial process generates the 5 MHz clock signal
	initial begin
		clk = 0;		        // initialise clock
		#0.1;		           // wait for global reset to finish
		forever
			begin
				#0.1;		     // delay 100 ns
				clk = ~clk;		// invert the clock
			end
	end
	
// This initial process defines the test sequence
	initial begin
		// Initialize Inputs
		rst = 1'b0;
		kpcol = 6'b0;
		// Initialise testbench signals
		sawnewkey = 1'b0;  	// initialise output detector
		keyCapture = 5'b0;	// initialise output register
		pressCol = 0;
		pressRow = 0;

		// Wait 100 ns for global reset to finish
		#0.1;        
		
		// Generate reset pulse of at least one clock cycle
		rst = 1;
		@(negedge clk);	// wait for falling clock edge
		@(negedge clk) rst = 0;		// end pulse at second falling edge
		
		// Let it run for a while to see rows being scanned
		#5000;
		
		//We begin by testing each keypad digit we expect to use
		PRESSKEY(0, 3, 0);    //digit 9 on keypad
        #30000;               //let it run to seperate input press'
		PRESSKEY(0, 4, 0);    //digit 8 on keypad
        #30000;               
        PRESSKEY(0, 5, 0);    //digit 7
        #30000;              
        PRESSKEY(0, 5, 0);    //digit 7 again, testing a key being pressed twice in a row
        #30000;
		PRESSKEY(1, 3, 0);    //digit 6
		#30000;			
		PRESSKEY(1, 4, 0);    //digit 5
		#30000;
		PRESSKEY(1, 5, 1);    //digit 4 - test reset being pressed in middle of key press
        #30000;            
        PRESSKEY(2, 3, 0);    //digit 3
        #30000;
        PRESSKEY(2, 4, 0);    //digit 2
        #30000;            
        PRESSKEY(2, 5, 0);    //digit 1
        #30000;	
 		PRESSKEY(3, 3, 0);   //key B, should be ignored
        #30000;
                
        rst = 1;                        //test reset in between keypresses
        @(negedge clk);                 
        @(negedge clk) rst = 0;        
            
        #15000
        PRESSKEY(3, 4, 0);  //key A - key_code should output 11 
        #30000;
        PRESSKEY(3, 5, 0);  //digit 0
        #30000;            
        
          
        //test presses quicker than sampling rate
        QUICKPRESSKEY(3, 4);
        #30000
        QUICKPRESSKEY(3, 5);
        #30000
        
        //test a very long press
        LONGPRESSKEY(2, 3);
        #30000
                        
		$stop;			// stop the simulation
	end

// This process simulates the keypad behaviour
	always @ (kprow or pressRow or pressCol)
		begin
			if (kprow == pressRow)  // if on row of interest
				kpcol = pressCol;	 // provide column input
			else
				kpcol = 6'b0;		 // otherwise all zero
		end

// This process captures output when newkey is 1, as specified
// and also changes a signal to make it easier to find newkey pulses
	always @ (posedge clk)
		if (newkey)		// same rule as next block in system would use
			begin
				keyCapture <= keycode;		// capture keycode
				sawnewkey <= ~sawnewkey;	// change state of signal
			end

// Task to simulate key press with bounce.  If reset is 1, simulates key press
// interrupted by reset press Call PRESSKEY(row, col, reset);
	task PRESSKEY (input integer pRow, pCol, dReset);
		integer pColPattern;		// local variable for column pattern
		begin
		   pColPattern = 1 << pCol;       // calculate column pattern
			pressRow = 1 << pRow;	      // set row pattern for given key
			pressCol = pColPattern;       // set column pattern
			#600 pressCol = 0;	          // let key bounce open after 0.6 ms
			#700 pressCol = pColPattern;  // then close again after 0.7 ms
			#25000                        //wait 25ms
			if(dReset)                   //if reset is high simulates reset
			     begin
			     rst = 1;
                 @(negedge clk);                
                 @(negedge clk) rst = 0;   
                 end
      
			#25000 pressCol = 0;	        // release after 25 ms
			#700 pressCol = pColPattern;	// bounce closed after 0.7 ms
			#1000 pressCol = 0;	            // finally open after 1 ms
			pressRow = 0;
		end
	endtask

// Task to simulate fast key press.  Call QUICKPRESSKEY(row, col);
	task QUICKPRESSKEY (input integer pRow, pCol);
		integer pColPattern;		// local variable for column pattern
		begin
		   pColPattern = 1 << pCol;   // calculate column pattern
			pressRow = 1 << pRow;	  // set row pattern for given key
			pressCol = pColPattern;	  // set column pattern
			#200 pressCol = 0;	      // release after 200 us
			pressRow = 0;
		end
	endtask

//Simulates a key being pressed for 1 second
//call LONGPRESSKEY(row, col)
	task LONGPRESSKEY (input integer pRow, pCol);
		integer pColPattern;		// local variable for column pattern
		begin
		   pColPattern = 1 << pCol;  // calculate column pattern
		   pressRow = 1 << pRow;	// set row pattern for given key
		   pressCol = pColPattern;	// set column pattern
		   #1000000 pressCol = 0;	// release after 1 s
		   pressRow = 0;
		end
	endtask

		
endmodule

