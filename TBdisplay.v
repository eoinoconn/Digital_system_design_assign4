`timescale 1us / 100ns
// Testbench for Display module
// Simulates operation of display

module TBdisplay;

	// Inputs of the module under test
	reg clk;
	reg rst;
	reg [1:0] status;
	reg [3:0] count;

	// Outputs from the module under test
	wire [1:0] tri_colour;
	wire [3:0] leds;
	
	// Instantiate the Unit Under Test (UUT)
	Display uut (
		.clk(clk), 
		.reset(rst), 
		.status(status), 
		.count(count), 
		.tri_colour(tri_colour), 
		.leds(leds)
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
	
//changes the value for every 10ms
    initial begin
        forever
            begin
                count = 4'b0000;
                #10000 count = 4'b0001;
                #10000 count = 4'b0010;
                #10000 count = 4'b0011;
                #10000;
            end
    end
	
// This initial process defines the test sequence
	initial begin
		// Initialize Inputs
		rst = 1'b0;
		status = 2'b0;

		// Wait 100 ns for global reset to finish
		#0.1;        
		
		// Generate reset pulse of at least one clock cycle
		rst = 1;
		@(negedge clk);	// wait for falling clock edge
		@(negedge clk) rst = 0;		// end pulse at second falling edge
		
		// Let it run
		#5000;
		
		SETSTATUS(2'b01, 0);         //sets the status to failed input attempt
		#50000 SETSTATUS(2'b10, 0);  //sets the status to succesful input attempt
		#50000 SETSTATUS(2'b01, 1);  //sets status to failed with reset in the middle
		#50000 SETSTATUS(2'b10, 1);  //sets status to succesful with reset in the middle
        
        
                
		$stop;			// stop the simulation
	end
//task to change input status, if reset is high, simulates reset in middle
//call SETSTATUS(status, reset)
	task SETSTATUS (input integer stat, dReset);
		begin
		   status = stat;
		   #25000
			if(dReset)                   //if reset is high simulates reset
                begin
                rst = 1;
                @(negedge clk);                
                @(negedge clk) rst = 0;   
                end 
		   #25000 status = 0;
		end
	endtask
	
endmodule