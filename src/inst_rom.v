`timescale 1ns / 1ps
module inst_rom (
    input wire [7:0] addr,
    output reg [31:0] dout
);

    reg [31:0] rom [0:255];

    initial begin
        $readmemh("program.mem", rom);
    end

    always @(*) begin
        dout = rom[addr];
    end

endmodule