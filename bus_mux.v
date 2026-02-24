module mux8to1 #(parameter W = 16) (
    input  wire [2:0]       sel,  
    input  wire [W-1:0]     in0,  
    input  wire [11:0]      in1,  
    input  wire [11:0]      in2,  
    input  wire [W-1:0]     in3,  
    input  wire [W-1:0]     in4,  
    input  wire [W-1:0]     in5,  
    input  wire [W-1:0]     in6,  
    input  wire [W-1:0]     in7,  
    output reg  [W-1:0]     y     
);

    always @(*) begin
        case (sel)
            3'b000: y = in0;
            3'b001: y = {{(W-12){1'b0}}, in1};  // AR is 12 bits
            3'b010: y = {{(W-12){1'b0}}, in2};  // PC is 12 bits
            3'b011: y = in3;
            3'b100: y = in4;
            3'b101: y = in5;
            3'b110: y = in6;
            3'b111: y = in7;
            default: y = {W{1'b0}};
        endcase
    end

endmodule