`timescale 1ns/1ps

module riscv_processor_top (
    input  wire        clk,
    input  wire        rst,        
    input  wire        led_sel,
    output wire [15:0] leds
);

    reg  [31:0] PC;
    wire [31:0] instruction;

    inst_rom INST_MEM (
        .clka  (clk),
        .addra (PC[7:0]), 
//        .addra (PC[9:2]),         
        .douta (instruction)
    );

    wire [5:0]  opcode = instruction[31:26];
    wire [3:0]  rs     = instruction[25:22];
    wire [3:0]  rt     = instruction[21:18];
    wire [3:0]  rd     = instruction[17:14];
    wire [5:0]  funct  = instruction[8:3];
    wire [15:0] imm16  = instruction[17:2];
    wire [25:0] imm26  = instruction[25:0];

    wire [31:0] rs_val, rt_val;
    reg  [31:0] wd;
    reg  [3:0]  rd_addr;
    reg         we;

    reg_bank RB (
        .clk (clk),
        .rst (rst),
        .we (we),
        .rd_addr (rd_addr),
        .rs1_addr (rs),
        .rs2_addr (rt),
        .wd (wd),
        .rs1 (rs_val),
        .rs2 (rt_val)
    );


    wire [31:0] imm32 = {{16{imm16[15]}}, imm16};
    wire  is_alu_imm =
          (opcode == 6'b001000) || (opcode == 6'b001001) ||
          (opcode == 6'b010000) || (opcode == 6'b010001) || (opcode == 6'b010010) ||
          (opcode == 6'b011000) || (opcode == 6'b011001) || (opcode == 6'b011010) ||
          (opcode == 6'b110000);

    wire [31:0] alu_out;
    wire alu_zero, alu_ovf;

    alu32 ALU (
        .rs1    (rs_val),
        .rs2    (is_alu_imm ? imm32 : rt_val),
        .opcode (opcode),
        .funct  (funct),
        .result (alu_out),
        .zero   (alu_zero),
        .ovf    (alu_ovf)
    );

    reg  [31:0] mem_addr_reg;     
    reg  [31:0] mem_wdata_reg;
    wire [31:0] mem_rdata;
    reg         mem_write_pulse;  

    data_bram data_mem (
        .clka  (clk),
        .ena   (1'b1),
        .wea   (mem_write_pulse),
        .addra (mem_addr_reg[9:2]),
        .dina  (mem_wdata_reg),
        .douta (mem_rdata)       
    );

    wire is_zero = (rs_val != 32'b0);
    wire branch_taken = ((opcode == 6'b111001) && rs_val[31]) ||  // BMI
                        ((opcode == 6'b111010) && (!rs_val[31] && is_zero)) || // BPL
                        ((opcode == 6'b111011) && !is_zero);     // BZ

    wire [31:0] next_PC_comb;
    pc_incrementer PCU (
        .PC           (PC),
        .opcode       (opcode),
        .imm16        (imm16),
        .imm26        (imm26),
        .rs_val       (rs_val),
        .branch_taken (branch_taken),
        .next_PC      (next_PC_comb)
    );

    reg [31:0] next_PC_hold;


    localparam [5:0] OP_LD   = 6'b101010;
    localparam [5:0] OP_ST   = 6'b101011;
    localparam [5:0] OP_HALT = 6'b101000;


    localparam [2:0]
        S_FETCH = 3'd0,   
        S_EXEC = 3'd1, 
        S_MEM1 = 3'd2,   
        S_MEM2 = 3'd3,   
        S_HALT = 3'd4;

    reg [2:0] state;

    reg       mem_is_load;
    reg [3:0] load_dest_reg;

    function [127:0] fsm_name;
        input [2:0] s;
        begin
            case (s)
                S_FETCH: fsm_name = "FETCH";
                S_EXEC : fsm_name = "EXEC";
                S_MEM1 : fsm_name = "MEM1";
                S_MEM2 : fsm_name = "MEM2";
                S_HALT : fsm_name = "HALT";
                default: fsm_name = "NONE";
            endcase
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            PC              <= 32'd0;
            state           <= S_FETCH;
            we              <= 1'b0;
            wd              <= 32'd0;
            rd_addr         <= 4'd0;
            mem_addr_reg    <= 32'd0;
            mem_wdata_reg   <= 32'd0;
            mem_write_pulse <= 1'b0;
            mem_is_load     <= 1'b0;
            load_dest_reg   <= 4'd0;
            next_PC_hold    <= 32'd1; 
        end else begin
            we              <= 1'b0;
            mem_write_pulse <= 1'b0;

            case (state)
            S_FETCH: begin
                state <= S_EXEC;
                $display("T=%0t [FETCH] PC=%0b", $time, PC);
            end

            S_EXEC: begin
                if (opcode == OP_HALT) begin
                    state <= S_HALT;
                    $display("T=%0t [EXEC] HALT", $time);
                end
                else if (opcode == OP_LD) begin
                    mem_is_load   <= 1'b1;
                    load_dest_reg <= rt;
                    mem_addr_reg  <= rs_val + imm32;
                    next_PC_hold  <= next_PC_comb; 
                    state         <= S_MEM1;
                    $display("T=%0t [EXEC] LD  rt=R%0d from [%0b]", $time, rt, rs_val + imm32);
                end
                else if (opcode == OP_ST) begin
                    mem_is_load    <= 1'b0;
                    mem_addr_reg   <= rs_val + imm32;
                    mem_wdata_reg  <= rt_val;
                    next_PC_hold   <= next_PC_comb;
                    state          <= S_MEM1;
                    $display("T=%0t [EXEC] ST  R%0d (%b) -> [%0b]",
                             $time, rt, rt_val, rs_val + imm32);
                end
                else if (opcode == 6'b000000) begin
                    case (funct)
                                6'b001000, 6'b001001,
                                6'b001100, 6'b001101,
                                6'b010000, 6'b010001, 6'b010010, 6'b010011,
                                6'b011010 : begin
                                    we      <= 1'b1;
                                    rd_addr <= rd;
                                    wd      <= alu_out;
                                    PC      <= next_PC_comb;
                                    state   <= S_FETCH;
                                    $display("T=%0t [EXEC] R-type  R%0d <= %b  nextPC=%b",
                                            $time, rd, alu_out, next_PC_comb);
                                end
                                6'b011011, 6'b011001, 6'b010100, 6'b101000 : begin
                                    we      <= 1'b1;
                                    rd_addr <= rt;
                                    wd      <= alu_out;
                                    PC      <= next_PC_comb;
                                    state   <= S_FETCH;
                                    $display("T=%0t [EXEC] R-type  R%0d <= %b  nextPC=%b",
                                            $time, rd, alu_out, next_PC_comb);
                                end
                                6'b001010, 6'b001011 : begin
                                    we      <= 1'b1;
                                    rd_addr <= rs;
                                    wd      <= alu_out;
                                    PC      <= next_PC_comb;
                                    state   <= S_FETCH;
                                    $display("T=%0t [EXEC] R-type  R%0d <= %b  nextPC=%b",
                                            $time, rd, alu_out, next_PC_comb);
                                end

                                6'b110000, 6'b110001: begin
                                    we      <= 1'b1;
                                    rd_addr <= rs;
                                    wd      <= rt_val;
                                    PC      <= next_PC_comb;
                                    state   <= S_FETCH;
                                    $display("T=%0t [EXEC] R-type  R%0d <= %b  nextPC=%b",
                                            $time, rd, alu_out, next_PC_comb);
                                end
                    endcase
                end else if (opcode == 6'b001000 || opcode == 6'b001001|| 
                            opcode == 6'b010000 ||
                            opcode == 6'b010001 || opcode == 6'b010010 ||
                            opcode == 6'b110000) begin
                    we      <= 1'b1;
                    rd_addr <= rt;
                    wd      <= alu_out;
                    PC      <= next_PC_comb;
                    state   <= S_FETCH;
                    $display("T=%0t [EXEC] I-type  R%0d <= %b  nextPC=%b",
                             $time, rt, alu_out, next_PC_comb);
                end else if (opcode == 6'b011000 || opcode == 6'b011001 || opcode == 6'b011010) begin
                    we      <= 1'b1;
                    rd_addr <= rs;
                    wd      <= alu_out;
                    PC      <= next_PC_comb;
                    state   <= S_FETCH;
                end
                else begin
                    PC    <= next_PC_comb;
                    state <= S_FETCH;
                    $display("T=%0t [EXEC] OTHER nextPC=%08h", $time, next_PC_comb);
                end
            end

            S_MEM1: begin
                if (!mem_is_load) begin
                    mem_write_pulse <= 1'b1;
                end
                state <= S_MEM2;
            end

            S_MEM2: begin
                if (mem_is_load) begin
                    we      <= 1'b1;
                    rd_addr <= load_dest_reg;
                    wd      <= mem_rdata;     // valid now
                    $display("T=%0t [LOAD-WB] R%0d <= %08h", $time, load_dest_reg, mem_rdata);
                end
                PC    <= next_PC_hold;
                state <= S_FETCH;
            end

            S_HALT: begin
                state <= S_HALT; 
            end

            default: state <= S_FETCH;
            endcase
        end
    end

    wire [31:0] led_reg_val = RB.regs[2];
    assign leds = led_sel ? led_reg_val[31:16] : led_reg_val[15:0];

endmodule