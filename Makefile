# 설정
VERILOG_SOURCES = ALU.v CPU.v CTRL.v GLOBAL.v MEM.v RF.v CPU_tb.v HAZARD.v
TOP_OUT = sim.out

TESTCASES = $(wildcard testcase*)

all: compile run_all

compile:
	iverilog -o $(TOP_OUT) $(VERILOG_SOURCES)

run_all:
	@echo "Starting all testcases..."
	@for dir in $(TESTCASES); do \
		if [ -d "$$dir" ]; then \
			echo "======================================"; \
			echo "Running $$dir..."; \
			rm -f initial_mem.mem initial_reg.mem reference_mem.mem reference_reg.mem; \
			cp "$$dir/initial_mem.mem"   . 2>/dev/null || echo "  [WARN] no initial_mem.mem in $$dir"; \
			cp "$$dir/initial_reg.mem"   . 2>/dev/null || echo "  [WARN] no initial_reg.mem in $$dir"; \
			cp "$$dir/reference_mem.mem" . 2>/dev/null || echo "  [WARN] no reference_mem.mem in $$dir"; \
			cp "$$dir/reference_reg.mem" . 2>/dev/null || echo "  [WARN] no reference_reg.mem in $$dir"; \
			vvp $(TOP_OUT); \
			echo "$$dir finished."; \
		fi \
	done
	@echo "======================================"
	@echo "All tests completed."

clean:
	rm -f $(TOP_OUT) *.vcd initial_mem.mem initial_reg.mem reference_mem.mem reference_reg.mem