module sequence_counter (
    input  wire       clk,
    input  wire       reset, 
    output reg  [3:0] T
);

    initial begin
        T = 4'b0000;
    end

    always @(posedge clk) begin
        if (reset) begin
            T <= 4'b0000;
        end
        else begin
            T <= T + 1'b1;
        end
    end

endmodule