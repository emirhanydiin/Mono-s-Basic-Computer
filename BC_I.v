module BC_I (
    input  clk,
    input  FGI,             
    output [11:0] PC,       
    output [11:0] AR,       
    output [15:0] IR,       
    output [15:0] AC,       
    output [15:0] DR,       
    output E   
);

    // Wires

    // From controller to datapath
    wire [2:0]  mux_sel;
    wire load_AR, inc_AR, clr_AR;
    wire load_PC, inc_PC, clr_PC;
    wire load_DR, inc_DR, clr_DR;
    wire load_AC, inc_AC, clr_AC;
    wire load_E,  inc_E,  clr_E;
    wire load_IR, clr_IR;
    wire load_TR, clr_TR;
    wire load_OUTR, clr_OUTR;
    wire load_IEN, inc_IEN, clr_IEN;
    wire load_R,   inc_R,   clr_R;
    wire load_start, inc_start, clr_start;

    wire mem_we;            
    wire [2:0] alu_op;

    // From datapath to controller
    wire IEN_status;        
    wire R;          
    wire CO, OVF, Z, N;

    // Wires for outputs
    wire [11:0] w_PC, w_AR;
    wire [15:0] w_IR, w_AC, w_DR;
    wire        w_E;

    assign PC = w_PC;
    assign AR = w_AR;
    assign IR = w_IR;
    assign AC = w_AC;
    assign DR = w_DR;
    assign E  = w_E;


    // Datapath
    datapath my_datapath (

        .clk(clk), 
        .FGI(FGI), 

        .mux_sel(mux_sel),
        
        .load_AR(load_AR), .inc_AR(inc_AR), .clr_AR(clr_AR),
        .load_PC(load_PC), .inc_PC(inc_PC), .clr_PC(clr_PC),
        .load_DR(load_DR), .inc_DR(inc_DR), .clr_DR(clr_DR),
        .load_AC(load_AC), .inc_AC(inc_AC), .clr_AC(clr_AC),
        .load_E(load_E),   .inc_E(inc_E),   .clr_E(clr_E),
        .load_IR(load_IR), .clr_IR(clr_IR),
        .load_TR(load_TR), .clr_TR(clr_TR),
        .load_start(load_start), .inc_start(inc_start), .clr_start(clr_start),
        
        .load_IEN(load_IEN), .inc_IEN(inc_IEN), .clr_IEN(clr_IEN),
        .load_R(load_R),     .inc_R(inc_R),     .clr_R(clr_R),

        .mem_we(mem_we), .alu_op(alu_op),
        
        // Outputs
        .AR(w_AR), .PC(w_PC), .IR(w_IR), .AC(w_AC), .DR(w_DR), .E(w_E), .start(start),
        .IEN_out(IEN_status), .R_out(R),
        .CO(CO), .OVF(OVF), .Z(Z), .N(N)
    );

    // Controller
    controller my_controller (

        .clk(clk), 
        .FGI(FGI),
        
        // Inputs
        .IR(w_IR),      
        .E(w_E), 
        .Z(Z), .N(N),   
        .IEN_status(IEN_status), 
        .R(R),
        .start(start),

        // Outputs
        .mux_sel(mux_sel),
        .load_AR(load_AR), .inc_AR(inc_AR), .clr_AR(clr_AR),
        .load_PC(load_PC), .inc_PC(inc_PC), .clr_PC(clr_PC),
        .load_DR(load_DR), .inc_DR(inc_DR), .clr_DR(clr_DR),
        .load_AC(load_AC), .inc_AC(inc_AC), .clr_AC(clr_AC),
        .load_E(load_E),   .inc_E(inc_E),   .clr_E(clr_E),
        .load_IR(load_IR), .clr_IR(clr_IR),
        .load_TR(load_TR), .clr_TR(clr_TR),
        .load_IEN(load_IEN),   .inc_IEN(inc_IEN),   .clr_IEN(clr_IEN),
        .load_R(load_R),       .inc_R(inc_R),       .clr_R(clr_R),
        .load_start(load_start), .inc_start(inc_start), .clr_start(clr_start),
        .mem_we(mem_we), .alu_op(alu_op)
    );
endmodule