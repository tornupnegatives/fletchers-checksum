VC=iverilog
VC_FLAGS=-g2012
BUILD_DIR=build

all: test

test: src/fletcher.sv test/fletcher_tb.sv
	@mkdir -p $(BUILD_DIR)
	$(VC) $(VC_FLAGS) -o $(BUILD_DIR)/$@ $^
	./$(BUILD_DIR)/$@

clean:
	@rm -rf $(BUILD_DIR)
	@rm -f *.vcd

