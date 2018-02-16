////////////////////////////////////////////////////////////////////////////////// 
// Engineer:        Eoin O'Connell 
// 
// Create Date:     16:27:24 03/08/2016  
// Module Name:     Keypad
// Description:     cycles kprow output and searches kpcol input for pushed keys, 
//                  applies slow sampling to avoid the effects of bounce. Outputs 
//                  a single bit pulse new_key, while simulateously outputting a 4
//                  bit key_code signal, both for 1 clock cycle
// 
// Revision 0.7
//////////////////////////////////////////////////////////////////////////////////
module keypad(
    input clk,
    input reset,
    input [5:0] kpcol,
	output reg [3:0] kprow,
	output reg [3:0] key_code,
	output reg new_key
    );
	
	
	reg [3:0]  Q1,
	           Q2,
	           Q3,
	           Q4,
	           Q5,
	           track1,
	           track2,
	           track3,
	           track4,
	           Q1next,
	           Q2next,
	           Q3next,
	           Q4next,
	           Q5next;
	
	reg [1:0]  sum,
	           nextS;
    
    reg [3:0]  row_out1,
               row_out2,
               row_out3,
               row_out4;
    
    wire       pulsig;
    
    //producing 2kHz pulse signal for cycling kprow values and slow sampling
	pulse #(.WIDTH(4'd12), .CYCLE(12'd2500)) keypad_pulse (.clk(clk), .reset(reset), .pulsig(pulsig));

	//Stage 1
	//Cycle kprow output activating each of 4 rows in turn
	//Register for sum
	always @(posedge clk, posedge reset)
		if(reset)	sum <= 2'b00;
		else        sum <= nextS;
		
	//combinational logic for sum
	always @(pulsig, sum)
		if(pulsig)         nextS = sum+2'b01;         
		else 				nextS = sum;
	
	always @ (sum)
		case(sum)
			2'b00:		kprow = 4'b1000;     //1 - active row, least significant is top row
			2'b01:		kprow = 4'b0100;
			2'b10:		kprow = 4'b0010;
			2'b11:		kprow = 4'b0001;
		endcase



	//stage 2
	//Multiplexer sets decimal value of signal depending on which columns and rows are high, if 
	//more than one colum or row is high output should be zero. Different wires take different values 
	//depending on which row is high
	always @ (kprow, kpcol)
		case({kprow, kpcol})
			10'b0001100000:		begin
			                     track1 = 4'd8;  //number 7 on keypad
			                     track2 = 4'd0;
                                 track3 = 4'd0;
                                 track4 = 4'd0;
                                end
			10'b0001010000:		 begin
			                     track1 = 4'd9;  //number 8
                                 track2 = 4'd0;
                                 track3 = 4'd0;
                                 track4 = 4'd0;
                                end
			10'b0001001000:		begin
			                     track1 = 4'd10; //number 9
                                 track2 = 4'd0;
                                 track3 = 4'd0;
                                 track4 = 4'd0;
			                    end
			10'b0010100000:		begin
			                     track2 = 4'd5;  //number 4
			                     track1 = 4'd0;
			                     track3 = 4'd0;
                                 track4 = 4'd0;
			                     end
			10'b0010010000:		begin
			                     track2 = 4'd6;  //number 5
			                     track1 = 4'd0;
                                 track3 = 4'd0;
                                 track4 = 4'd0;
                                end
			10'b0010001000:		begin
			                     track2 = 4'd7;  //number 6
			                     track1 = 4'd0;
                                 track3 = 4'd0;
                                 track4 = 4'd0;
                                end
			10'b0100100000:		begin
			                    track3 = 4'd2;  //number 1
			                    track1 = 4'd0;
                                track2 = 4'd0;
                                track4 = 4'd0;			                    
                                end
			10'b0100010000:		begin
			                     track3 = 4'd3;  //number 2
			                     track1 = 4'd0;
                                 track2 = 4'd0;
                                 track4 = 4'd0;
                                end
			10'b0100001000:		begin
			                    track3 = 4'd4;  //number 3
			                    track1 = 4'd0;
                                track2 = 4'd0;
                                track4 = 4'd0;
                                end
			10'b1000100000:		begin
			                     track4 = 4'd1;  //number 0
			                     track1 = 4'd0;
			                     track2 = 4'd0;
			                     track3 = 4'd0;
                                end
			10'b1000010000:		begin
			                    track4 = 4'd11; //letter A - usused as backspace
			                    track1 = 4'd0;
			                    track2 = 4'd0;
			                    track3 = 4'd0;
                                end
            default:            begin
                                    track1=4'd0; 
                                    track2=4'd0; 
                                    track3=4'd0; 
                                    track4=4'd0;
                                end
		endcase

        
		//////1st row
		//register for edge detector
    always @(posedge clk, posedge reset)
            if(reset)    Q1 <= 4'd0;
            else         Q1 <= Q1next;
        //register logic, activates on pulsig and sum
    always @(track1, Q1, sum, pulsig)
            if ((sum == 2'b11)&&(pulsig))
                Q1next = track1;
            else
                Q1next = Q1;
                    
        //edge detector logic
    always @(Q1, Q1next)
            if((Q1next != 0)&&(Q1 == 0))
                row_out1 = Q1next;
            else row_out1 = 0;

		//////2nd row
	always @(posedge clk, posedge reset)
            if(reset)    Q2 <= 4'd0;
            else         Q2 <= Q2next;
    
    always @(track2, Q2, pulsig, sum)
            if ((sum == 2'b10)&&(pulsig))
                Q2next = track2;
            else
                Q2next = Q2;

    always @(Q2, Q2next)
        if((Q2next != 0)&&(Q2 == 0))
            row_out2 = Q2next;
        else row_out2 = 0;
        
       

		//////3rd row
	always @(posedge clk, posedge reset)
          if(reset)    Q3 <= 4'd0;
          else         Q3 <= Q3next;
        
    always @(track3, Q3, sum, pulsig)
          if ((sum == 2'b01)&&(pulsig))
            Q3next = track3;
          else
            Q3next = Q3;
    
    always @(Q3, Q3next)
          if((Q3next != 0)&&(Q3 == 0))
                row_out3 = Q3next;
          else row_out3 = 0;


		//////4th row
    always @(posedge clk, posedge reset)
          if(reset)    Q4 <= 4'd0;
          else         Q4 <= Q4next;
        
    always @(track4, Q4, sum, pulsig)
          if ((sum == 2'b00)&&(pulsig))
             Q4next = track4;
          else
             Q4next = Q4;
    
    always @(Q4, Q4next)
          if((Q4next != 4'd0)&&(Q4 == 4'd0))
            row_out4 = Q4next;
          else row_out4 = 0;

	//stage 3
	//output
	
	//output register logic
	//pririty given to top row. If previous row had output
	always @(row_out1, row_out2, row_out3, row_out4, sum)
	   case(sum)
           2'b11:      key_code = row_out1;
           2'b10:      key_code = row_out2;
           2'b01:      key_code = row_out3;
           2'b00:      key_code = row_out4;
	   endcase
	   
    //new_key combinational logic
	 always @(key_code)
	   if(key_code != 4'd0) new_key = 1'b1;
	   else new_key = 1'b0;  
	 
endmodule