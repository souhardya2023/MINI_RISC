// `timescale 1ns / 1ps
// module data_bram(
//     input wire clka,
//     input wire ena,
//     input wire wea,
//     input wire [7:0] addra,
//     input wire [31:0] dina,
//     output wire [31:0] douta
// );

    
//     blk_mem_gen_0 bram_ip (
//         .clka(clka),
//         .ena(ena),
//         .wea(wea),
//         .addra(addra),
//         .dina(dina),
//         .douta(douta)
//     );

// endmodule

`timescale 1ns / 1ps
module data_bram(
    input wire clka,
    input wire ena,
    input wire wea,
    input wire [7:0] addra,
    input wire [31:0] dina,
    output reg [31:0] douta
);

    reg [31:0] mem [0:255];

    always @(posedge clka) begin
        if (ena) begin
            if (wea)
                mem[addra] <= dina;

            douta <= mem[addra];
        end
    end

endmodule