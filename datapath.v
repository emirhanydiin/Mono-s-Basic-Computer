module datapath (
    // Inputs
    input  wire        clk,
    input  wire        FGI, 

    input  wire        mem_we,
    input  wire [2:0]  alu_op,

    input  wire [2:0]  mux_sel,
    
    input  wire        load_AR, inc_AR, clr_AR,
    input  wire        load_PC, inc_PC, clr_PC,
    input  wire        load_DR, inc_DR, clr_DR,
    input  wire        load_AC, inc_AC, clr_AC,
    input  wire        load_E,  inc_E,  clr_E,
    input  wire        load_IR, clr_IR,      
    input  wire        load_TR, clr_TR,       
    input  wire        clr_start, load_start, inc_start, 
    input  wire        load_IEN, inc_IEN, clr_IEN,
    input  wire        load_R,   inc_R,   clr_R,

    // Outputs 
    output wire        E,
    output wire        IEN_out,
    output wire        R_out,
    output wire        start,
    output wire        CO, OVF, Z, N,
    output wire [11:0] AR,
    output wire [11:0] PC,
    output wire [15:0] IR,
    output wire [15:0] AC,
    output wire [15:0] DR
);

    // Internal Wires 
    wire [15:0] data_bus;
    wire [15:0] mem_read_data;
    wire [15:0] alu_out;
    wire [15:0] tr_out; 
    wire        e_out;

    // Start (1 bit)
    register #(.W(1)) start_reg (
        .clk(clk), .reset(clr_start), .we(load_start), .inc(inc_start), 
        .data(1'b0), .out(start)
    );

    // IEN Interrupt Enable (1 bit)
    register #(.W(1)) ien (
        .clk(clk), .reset(clr_IEN), .we(load_IEN), .inc(inc_IEN), 
        .data(1'b1), .out(IEN_out)
    );

    // R Interrupt Request Flip-Flop (1 bit)
    register #(.W(1)) r (
        .clk(clk), .reset(clr_R), .we(load_R), .inc(inc_R), 
        .data(1'b1), .out(R_out)
    );

    // AR (12 bits)
    register #(.W(12)) ar (
        .clk(clk), .reset(clr_AR), .we(load_AR), .inc(inc_AR), 
        .data(data_bus[11:0]), .out(AR)
    );

    // PC (12 bits)
    register #(.W(12)) pc (
        .clk(clk), .reset(clr_PC), .we(load_PC), .inc(inc_PC), 
        .data(data_bus[11:0]), .out(PC)
    );

    // DR
    register #(.W(16)) dr (
        .clk(clk), .reset(clr_DR), .we(load_DR), .inc(inc_DR), 
        .data(data_bus), .out(DR)
    );

    // AC
    register #(.W(16)) ac (
        .clk(clk), .reset(clr_AC), .we(load_AC), .inc(inc_AC), 
        .data(alu_out), .out(AC)
    );

    // E
    register #(.W(1)) e (
        .clk(clk), .reset(clr_E), .we(load_E), .inc(inc_E), 
        .data(e_out), .out(E)
    );

    // IR
    register #(.W(16)) ir (
        .clk(clk), .reset(clr_IR), .we(load_IR), .inc(1'b0), 
        .data(data_bus), .out(IR)
    );

    // TR
    register #(.W(16)) tr (
        .clk(clk), .reset(clr_TR), .we(load_TR), .inc(1'b0), 
        .data(data_bus), .out(tr_out)
    );

    // ALU 
    alu #(.W(16)) alu ( 
        .AC(AC), .DR(DR), .E_in(E), .op(alu_op), 
        .out(alu_out), .CO(CO), .OVF(OVF), .Z(Z), .N(N), .E_out(e_out) 
    );

    // Memory
    memory_unit mem ( 
        .clk(clk), .we(mem_we), .address(AR), .write_data(data_bus), .read_data(mem_read_data) 
    );

    // Multiplexer 
    mux8to1 #(.W(16)) mux (
        .sel(mux_sel), 
        .in0(16'h0000), 
        .in1(AR), 
        .in2(PC), 
        .in3(DR),
        .in4(AC), 
        .in5(IR), 
        .in6(tr_out), 
        .in7(mem_read_data), 
        .y(data_bus)
    );

endmodule