module pc_incrementer(
    input  [31:0] PC,
    input  [5:0]  opcode,
    input  [15:0] imm16,
    input  [25:0] imm26,
    input  [31:0] rs_val,
    input         branch_taken,
    output reg [31:0] next_PC
);
    wire [31:0] PC_plus_1 ;
    wire [31:0] PC_branch16;
    wire [31:0] PC_branch26;
    wire [31:0] imm16_ext  = {{16{imm16[15]}}, imm16};
    wire [31:0] imm26_ext  = {{6{imm26[25]}}, imm26};

    ripple_adder_32 PC_INC (
    .a(PC),
    .b(32'd1),
    .cin(1'b0),
    .sum(PC_plus_1),
    .cout(),
    .overflow()
    );

    ripple_adder_32 PC_BRANCH16_ADDER (
    .a(PC_plus_1),
    .b(imm16_ext),
    .cin(1'b0),
    .sum(PC_branch16),
    .cout(),
    .overflow()
    );

    always @(*) begin
        next_PC = PC_plus_1; // default
        if (opcode == 6'b111000)         // Jump
            next_PC = imm26_ext;
        else if (branch_taken)           // Branch
            next_PC = PC_branch16;
    end
endmodule
