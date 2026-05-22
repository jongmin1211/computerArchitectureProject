# 설정
VERILOG_SOURCES = ALU.v CPU.v CTRL.v GLOBAL.v MEM.v RF.v CPU_tb.v HAZARD.v
TOP_OUT = sim.out

# 현재 디렉토리에서 'testcase'로 시작하는 모든 디렉토리 찾기
TESTCASES = $(wildcard testcase*)

# 기본 실행
all: compile run_all

# 1. 컴파일
compile:
	iverilog -o $(TOP_OUT) $(VERILOG_SOURCES)

# 2. 모든 테스트케이스 순회 실행
run_all:
	@echo "Starting all testcases..."
	@for dir in $(TESTCASES); do \
		if [ -d $$dir ]; then \
			echo "--------------------------------------"; \
			echo "Running $$dir..."; \
			cp $$dir/*.hex . 2>/dev/null || true; \
			cp $$dir/*.mem . 2>/dev/null || true; \
			vvp $(TOP_OUT); \
			echo "$$dir finished."; \
		fi \
	done
	@echo "--------------------------------------"
	@echo "All tests completed."

clean:
	rm -f $(TOP_OUT) *.vcd *.hex *.mem