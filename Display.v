`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.04.2016 17:53:48
// Design Name: 
// Module Name: Display
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Display(
    output reg [1:0] tri_colour,
    output reg [2:0] leds,
    input [1:0] status,
    input [3:0] count,
    input clk,
    input reset
    );
    
    parameter RED = 2'b01;
    parameter GREEN = 2'b10;
    parameter OFF = 2'b00;
    reg [1:0] tri_colour_next;
    
   wire pulsig;
    
    pulse #(.WIDTH(5'd22), .CYCLE(22'd25000)) display_pulse (.clk(clk), .reset(reset), .pulsig(pulsig));


    //sets the output to leds depending on count from lock    
   always @ (count)
        if (count == 3'b001)
            leds = 3'b001;
        else if (count == 3'b010)
            leds = 3'b011;
        else if (count == 3'b011)
            leds = 3'b111;
        else
            leds = 3'b000;
     //sets next value RGB led
    always @ (status, tri_colour, pulsig)
        if (((status == 2'b01) && (tri_colour == OFF) && pulsig)||(status == 2'b00))    //if status is failed and led is off or status is idle
            tri_colour_next = RED;
        else if ((((status == 2'b01) && (tri_colour == RED))||((status == 2'b10) && (tri_colour == GREEN))) && pulsig)  //if status is failed and led is off or status is unlock and led is green
            tri_colour_next = OFF;
        else if((status == 2'b10) && ((tri_colour == RED)||(tri_colour == OFF)) && pulsig)  //if status is unlock and led is red or off
            tri_colour_next = GREEN;
        else
            tri_colour_next = tri_colour;
     //rei  colour register
    always @ (posedge clk, posedge reset)
        if (reset) tri_colour = OFF;
        else tri_colour = tri_colour_next;
    
    
endmodule