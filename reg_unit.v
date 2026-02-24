module register #(parameter W = 16) (
    input  wire             clk,
    input  wire             reset, 
    input  wire             we,   
    input  wire             inc,  
    input  wire [W-1:0]     data,  
    output reg  [W-1:0]     out      
);

    initial begin
        out = {W{1'b0}};
    end

    always @(posedge clk) begin
        if (reset) begin
            out <= {W{1'b0}};      
        end 
        else if (we) begin
            out <= data;          
        end 
        else if (inc) begin
            out <= out + 1'b1;      
        end
    end

endmodule