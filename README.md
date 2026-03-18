# 🧠 MINI RISC Processor — 32-bit Verilog Implementation

## 📌 Overview

This repository contains the complete design, simulation, and verification of a **custom 32-bit RISC processor**, implemented in Verilog. The project is structured to support both:

* **FPGA-based synthesis (Vivado-compatible design)**
* **Simulator-based validation (GitHub Actions using Icarus Verilog)**

The processor integrates modular ALU components, instruction decoding logic, register banks, and memory units to execute a defined instruction set.

---

## 🎯 Objectives

* Design a modular **32-bit RISC architecture**
* Implement arithmetic, logical, and control operations
* Integrate **instruction memory (ROM)** and **data memory (RAM)**
* Enable **automated simulation and validation via CI/CD**
* Maintain compatibility with both:

  * FPGA toolchains (Vivado)
  * Open-source simulators (Icarus Verilog)

---

## 🏗️ Repository Structure

```
MINI_RISC/
├── src/                        # Core Verilog modules
│   ├── processor_top.v        # Top-level processor module
│   ├── alu32.v                # Arithmetic Logic Unit
│   ├── arith_unit32.v         # Arithmetic unit
│   ├── logic_unit32.v         # Logical operations
│   ├── shifter_32.v           # Shift operations
│   ├── mov_unit_32.v          # Move operations
│   ├── lui_unit32.v           # Load Upper Immediate
│   ├── reg_bank.v             # Register file
│   ├── pc_incrementer.v       # Program counter logic
│   ├── data_bram.v            # Data memory (behavioral model)
│   ├── inst_rom.v             # Instruction memory (ROM)
│   └── ...                    # Supporting modules
│
├── testbench/
│   └── processor_top_testbench.v   # Simulation testbench
│
├── coe/                        # Memory initialization files (Vivado)
│   ├── program_*.coe
│   └── memory_*.coe
│
├── constraints/
│   └── pin.xdc                # FPGA constraints
│
├── ip_xci_files/              # Vivado IP configurations
│   ├── blk_mem_gen_0/
│   └── inst_rom/
│
├── .github/workflows/
│   └── verilog.yml            # CI workflow for simulation
│
├── program.mem                # Simulation instruction memory
├── .gitignore
└── README.md
```

---

## ⚙️ Processor Architecture

### 🔹 Core Components

* **ALU (alu32.v)**
  Handles arithmetic and logical computations.

* **Arithmetic Unit**
  Supports addition, subtraction, and related operations.

* **Logic Unit**
  Implements AND, OR, XOR, etc.

* **Shifter Unit**
  Performs logical and arithmetic shifts.

* **Register Bank**
  Stores intermediate and final computation values.

* **Program Counter (PC)**
  Manages instruction sequencing.

---

### 🔹 Memory System

#### 🧾 Instruction Memory (ROM)

* Implemented as a behavioral ROM using:

  ```verilog
  $readmemh("program.mem", rom);
  ```
* Stores executable instructions
* Addressed via program counter

#### 💾 Data Memory (RAM)

* Behavioral replacement of Vivado Block RAM
* Supports read/write operations
* Indexed using word-aligned addressing

---

## 🧪 Simulation & Verification

### 🔹 Local Simulation

```bash
iverilog -o sim.vvp src/*.v testbench/processor_top_testbench.v
vvp sim.vvp
```

### 🔹 Output

* Console logs from `$display`
* Optional waveform generation (`.vcd`)

---

## 🤖 Continuous Integration (CI)

This project uses **GitHub Actions** to automate:

* Compilation of all Verilog modules
* Execution of testbench
* Detection of syntax and runtime errors

### Workflow File:

```
.github/workflows/verilog.yml
```

### CI Steps:

1. Checkout repository
2. Install Icarus Verilog
3. Compile design + testbench
4. Run simulation

---

## ⚠️ Vivado vs Simulation Compatibility

### 🔴 Problem

Vivado IPs like:

* `blk_mem_gen_0`
* `inst_rom`

are **not supported in Icarus Verilog**

---

### ✅ Solution

We provide **behavioral replacements**:

| Vivado IP       | Simulation Replacement |
| --------------- | ---------------------- |
| Block RAM       | `data_bram.v`          |
| Instruction ROM | `inst_rom.v`           |

---

## 📄 program.mem

### 📌 Purpose

Defines instruction memory for simulation.

### 📌 Format

* Hexadecimal (32-bit per line)

Example:

```
00000013
00100093
00200113
00308193
```

---

## 🧠 Design Philosophy

* **Modularity** → Each functional unit is isolated
* **Portability** → Works across tools (Vivado + Icarus)
* **Reproducibility** → CI ensures consistent results
* **Scalability** → Easy to extend instruction set

---

## 🚀 Extending the Project

You can enhance this processor by:

* Adding branching and control flow
* Implementing pipelining
* Supporting interrupts
* Integrating cache memory
* Adding hazard detection

---

## 🧩 Known Limitations

* No pipeline (single-cycle or basic execution)
* Limited instruction set
* No hazard handling
* Behavioral memory not cycle-accurate to FPGA BRAM

---

## 👨‍💻 Authors

* Souhardya Dandapat
* Utsa Ghosh

---

## 📜 License

This project is intended for academic and educational use.

---

## ⭐ Final Notes

This repository demonstrates a **complete digital system design workflow**, including:

* RTL design
* Simulation
* CI/CD integration
* FPGA compatibility

It reflects **industry-grade practices** in hardware design and verification.

---
