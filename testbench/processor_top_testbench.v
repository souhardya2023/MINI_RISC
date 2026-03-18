`timescale 1ns/1ps

module tb_minirisc_xdbg;

  // ---------------- Clock & Reset ----------------
  reg clk   = 1'b0;
  reg reset = 1'b1;

  always #5 clk = ~clk; // 100 MHz clock

  // ---------------- DUT ----------------
  riscv_processor_top dut (
    .clk     (clk),
    .rst     (reset),
    .led_sel (1'b0),
    .leds    ()
  );

  // ---------------- Encodings ----------------
  localparam [5:0] OP_HALT = 6'b101000;

  // ---------------- Formatted debug printer ----------------
  task automatic show_line;
    begin
      $display("\n------------------------------------------------------------");
      $display("Cycle @ %0t ns | PC = %08x | OPCODE = %06b", 
                $time, dut.PC, dut.opcode);
      $display("------------------------------------------------------------");

      // Instruction breakdown
      $display("INSTR  = %08x", dut.instruction);
      $display("FIELDS = OP:%02x | rs:%0d | rt:%0d | rd:%0d | fn:%02x | imm16:%04x | imm26:%07x",
               dut.opcode, dut.rs, dut.rt, dut.rd, dut.funct,
               dut.imm16, dut.imm26);

      // Core state summary
      $display("\n[Control]");
      $display("  state         = %0d", dut.state);
      $display("  branch_taken  = %b", dut.branch_taken);
      $display("  write_enable  = %b (rd=%0d, wd=%08x)", dut.we, dut.rd_addr, dut.wd);

      // Register file
      $display("\n[Registers]");
      $display("  RS = R%-2d = 0x%08x", dut.rs, dut.rs_val);
      $display("  RT = R%-2d = 0x%08x", dut.rt, dut.rt_val);

      // ALU and immediate
      $display("\n[ALU Path]");
      $display("  OperandA = %08x", dut.rs_val);
      $display("  OperandB = %08x  (is_imm=%0d)", 
                dut.is_alu_imm ? {{16{dut.imm16[15]}}, dut.imm16} : dut.rt_val, 
                dut.is_alu_imm);
      $display("  Result   = %08x | Zero=%b | Ovf=%b",
               dut.alu_out, dut.alu_zero, dut.alu_ovf);

      // Memory
      $display("\n[Memory]");
      $display("  is_load   = %0d", dut.mem_is_load);
      $display("  write_pulse = %0d", dut.mem_write_pulse);
      $display("  Address   = %08x  (idx %0d)", dut.mem_addr_reg, dut.mem_addr_reg[9:2]);
      $display("  WData     = %08x", dut.mem_wdata_reg);
      $display("  RData     = %08x", dut.mem_rdata);

      // PC and branching
      $display("\n[Branch & PC]");
      $display("  taken     = %0d", dut.branch_taken);
      $display("  next_PC_comb = %08x", dut.next_PC_comb);
      $display("  next_PC_hold = %08x", dut.next_PC_hold);
    end
  endtask

  // ---------------- Test sequence ----------------
  integer i, cycles, halt_seen;

  initial begin
    `ifdef DUMP_WAVE
      $dumpfile("minirisc_xdbg.fst");
      $dumpvars(0, tb_minirisc_xdbg);
    `endif

    // Hold reset
    repeat (8) @(posedge clk);
    reset <= 1'b0;

    $display("\n============================================================");
    $display("   MINI-RISC FULL DEBUG RUN STARTED");
    $display("============================================================");

    cycles = 0;
    halt_seen = 0;

    // Execution loop
    while ((cycles < 5000) && (halt_seen == 0)) begin
      @(negedge clk);
      $display("\n>> CYCLE #%0d", cycles);
      show_line();

      @(posedge clk);
        cycles = cycles + 1;

      if (dut.instruction[31:26] == OP_HALT) begin
        halt_seen = 1;
        @(posedge clk); // final edge
      end
    end

    $display("\n============================================================");
    $display("   FINAL STATE (cycles=%0d, halt_detected=%0d)", cycles, halt_seen);
    $display("============================================================");

    // Register dump
    $display("\n--- Register File Dump ---");
    for (i = 0; i < 16; i = i + 1)
      $display("R%-2d = 0x%08x", i, dut.RB.regs[i]);

    $display("\n--- Done ---\n");
    $finish;
  end

endmodule
