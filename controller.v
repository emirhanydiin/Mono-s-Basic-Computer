module controller (
    input  wire        clk, 
    input  wire        FGI,
    input  wire [15:0] IR,
    input  wire        E, Z, N, 
    input  wire        IEN_status,      
    input  wire        R,
    input  wire        start,
    input  wire [3:0]  T,

    // Control Signals
    output reg         load_AR, inc_AR, clr_AR,
    output reg         load_PC, inc_PC, clr_PC,
    output reg         load_DR, inc_DR, clr_DR,
    output reg         load_AC, inc_AC, clr_AC,
    output reg         load_E,  inc_E,  clr_E,
    output reg         load_IR, clr_IR,
    output reg         load_TR, clr_TR,
    output reg         load_IEN, inc_IEN, clr_IEN,
    output reg         load_R,   inc_R,   clr_R,
    output reg         mem_we,
    output reg         load_start, inc_start, clr_start,
    output reg  [2:0]  mux_sel,
    output reg  [2:0]  alu_op,
    output reg         clr_T
);
    
    // Instruction Decoding 
    wire I; 
    wire [2:0] D; 
    assign I = IR[15];     // Indirect
    assign D = IR[14:12];  // Opcode

    // States
    //reg [3:0] T; 
    //reg clr_T; 

    sequence_counter seq_cnt (
        .clk(clk),  
        .reset(clr_T), 
        .T(T)            
    );

    always @(*) begin

        mux_sel = 3'b000;
        mem_we=0;
        alu_op = 3'b110; 
        clr_T = 0; 

        load_AR=0; inc_AR=0; clr_AR=0;
        load_PC=0; inc_PC=0; clr_PC=0;
        load_DR=0; inc_DR=0; clr_DR=0;
        load_AC=0; inc_AC=0; clr_AC=0;
        load_E=0;  inc_E=0;  clr_E=0;
        load_IR=0; clr_IR=0;
        load_TR=0; clr_TR=0;
        load_IEN=0; inc_IEN=0; clr_IEN=0;
        load_R=0;   inc_R=0;   clr_R=0;

        // Interrupt Check
        if (start == 1'b0) begin
            if (T > 2 && IEN_status && FGI && !R) begin
                load_R = 1;
            end

            // Interrupt Cycle when R=1
            if (R) begin
                case (T)
                    0: clr_AR = 1; 
                    1: begin 
                        mux_sel = 3'b010; 
                        mem_we = 1;       
                        clr_PC = 1;       
                        end
                    2: begin 
                        inc_PC = 1;       
                        clr_IEN = 1;      
                        clr_R = 1;        
                        clr_T = 1;      
                        end
                endcase
            end

            // Fetch & Decode 

            else if (!R && T < 3) begin

                if(T == 0) begin
                    mux_sel = 3'b010; // PC on Bus
                    load_AR = 1;
                end

                if(T == 1) begin
                    inc_PC = 1;
                    mux_sel = 3'b111; // Memory on Bus
                    load_IR = 1;
                end

                if(T == 2) begin
                    mux_sel = 3'b101; // IR on Bus
                    load_AR = 1;
                end
            end
            
            // EXECUTION PHASE

            if (T >= 3) begin
                // REGISTER REFERENCE / IO Reference
                if(D == 7 && T == 3) begin
                    clr_T = 1;
                    if(I == 0) begin 
                        if(IR[11]) clr_AC = 1;
                        if(IR[10]) clr_E = 1;  
                        if(IR[9])  begin alu_op = 3'b011; load_AC = 1; end // CMA
                        if(IR[8])  begin alu_op = 3'b110; inc_E = 1; end // CME
                        if(IR[7])  begin alu_op = 3'b100; load_AC = 1; load_E = 1; end // CIR
                        if(IR[6])  begin alu_op = 3'b101; load_AC = 1; load_E = 1; end // CIL
                        if(IR[5])  inc_AC = 1; // INC
                        if(IR[4])  begin if(!N) inc_PC = 1; end // SPA
                        if(IR[3])  begin if(N)  inc_PC = 1; end // SNA
                        if(IR[2])  begin if(Z)  inc_PC = 1; end // SZA
                        if(IR[1])  begin if(!E) inc_PC = 1; end // SZE
                        if(IR[0])  begin inc_start = 1'b1; end // HLT
                    end
                    else begin // I/O Ref (I=1)
                        if(IR[7]) inc_IEN = 1; // ION
                        if(IR[6]) clr_IEN = 1; // IOF
                    end
                end
            
                // INDIRECT ADDRESSING
                if(D != 7 && I == 1 && T == 3) begin
                    mux_sel = 3'b111; // Memory on Bus
                    load_AR = 1;        
                end

                // EXECUTE PHASES

                // AND 
                if(D == 0) begin
                    if(T == 4) begin 
                        mux_sel = 3'b111; // Memory on Bus
                        load_DR = 1; 
                    end
                    else if(T == 5) begin 
                        alu_op = 3'b001; 
                        load_AC = 1; 
                        clr_T = 1; 
                    end
                end

                // ADD 
                else if(D == 1) begin
                    if(T == 4) begin 
                        mux_sel = 3'b111; // Memory on Bus
                        load_DR = 1; 
                    end
                    else if(T == 5) begin 
                        alu_op = 3'b000; 
                        load_AC = 1; 
                        load_E = 1; 
                        clr_T = 1; 
                    end
                end

                // LDA 
                if(D == 2) begin
                    if(T == 4) begin 
                        mux_sel = 3'b111; // Memory on Bus
                        load_DR = 1; 
                        end
                    else if(T == 5) begin 
                        alu_op = 3'b010; 
                        load_AC = 1; 
                        clr_T = 1; 
                    end
                end

                // STA
                if(D == 3) begin
                    if(T == 4) begin 
                        mux_sel = 3'b100; 
                        mem_we = 1; 
                        clr_T = 1; 
                    end
                end

                // BUN 
                if(D == 4) begin
                    if(T == 4) begin 
                        mux_sel = 3'b001; // AR on Bus
                        load_PC = 1;        
                        clr_T = 1;
                    end
                end

                // BSA 
                if(D == 5) begin
                    if(T == 4) begin 
                        mux_sel = 3'b010; 
                        mem_we = 1; 
                        inc_AR = 1; 
                    end
                    else if(T == 5) begin 
                        mux_sel = 3'b001; 
                        load_PC = 1; 
                        clr_T = 1; 
                    end
                end

                // ISZ 
                if(D == 6) begin
                    if(T == 4) begin 
                        mux_sel = 3'b111; 
                        load_DR = 1; 
                    end
                    else if(T == 5) begin 
                        inc_DR = 1; 
                    end
                    else if(T == 6) begin 
                        mux_sel = 3'b011; 
                        mem_we = 1; 
                        alu_op = 3'b010;
                        clr_T = 1; 
                        if(Z) begin
                            inc_PC = 1; 
                        end 
                    end
                end
            end
        end
    end
endmodule