module alu #(parameter W = 16) (
    input  wire [W-1:0] AC,    
    input  wire [W-1:0] DR,    
    input  wire         E_in,  
    input  wire [2:0]   op,    
    output reg  [W-1:0] out,   
    output reg          CO,    // Carry Out
    output reg          OVF,   // Overflow
    output reg          Z,     // Zero 
    output reg          N,     // Negative
    output reg          E_out  
);
    reg [W:0] temp;

    always @(*) begin
        out   = {W{1'b0}};
        CO    = 1'b0;
        OVF   = 1'b0;
        E_out = E_in;
        temp = {W+1{1'b0}};

        case (op)
            3'b000: begin // ADD: out = AC + DR
                temp = {1'b0, AC} + {1'b0, DR};
                out = temp[W-1:0];
                OVF = (AC[W-1] & DR[W-1] & ~out[W-1]) | (~AC[W-1] & ~DR[W-1] & out[W-1]);
                CO = temp[W];
                E_out = CO;
            end

            3'b001: begin // AND
                out = AC & DR;
                CO  = 1'b0;
                OVF = 1'b0;
            end

            3'b010: begin // Transfer DR
                out = DR;
                CO  = 1'b0;
                OVF = 1'b0;
            end

            3'b011: begin // Complement AC
                out = ~AC; 
                CO  = 1'b0; 
                OVF = 1'b0;
            end

            3'b100: begin // Shift Right
                out   = {E_in, AC[W-1:1]};
                E_out = AC[0];
                CO    = 1'b0;
                OVF   = 1'b0;
            end

            3'b101: begin // Shift Left
                out   = {AC[W-2:0], E_in};
                E_out = AC[W-1];
                CO    = 1'b0;
                OVF   = 1'b0;
            end

            3'b110: begin // Transfer AC 
                out = AC;
                CO  = 1'b0;
                OVF = 1'b0;
            end

            default: begin
                out = {W{1'b0}};
                CO  = 1'b0;
                OVF = 1'b0;
            end
        endcase
        
        Z = (out == {W{1'b0}});
        N = out[W-1];
    end

endmodule