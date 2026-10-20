`timescale 1ns/1ps

module tb_register_file;

    reg clk;
    reg reset;
    reg write_enable;

    reg [4:0] write_address;
    reg [31:0] write_data;

    reg [4:0] read_address_A;
    reg [4:0] read_address_B;

    wire [31:0] read_data_A;
    wire [31:0] read_data_B;

    reg [31:0] expected [0:31];

    integer i;
    integer errors;

    // DUT: Register File
    register_file DUT (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .write_address(write_address),
        .write_data(write_data),
        .read_address_A(read_address_A),
        .read_address_B(read_address_B),
        .read_data_A(read_data_A),
        .read_data_B(read_data_B)
    );

    // 10 ns clock period
    always #5 clk = ~clk;


    // Task: Write one register
    task write_reg;
        input [4:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            write_enable = 1'b1;
            write_address = addr;
            write_data = data;

            @(posedge clk);
            #1;

            expected[addr] = data;
        end
    endtask


    // Task: Check both asynchronous read ports
    task check_reads;
        input [4:0] addr_a;
        input [4:0] addr_b;
        begin
            @(negedge clk);

            read_address_A = addr_a;
            read_address_B = addr_b;

            #1;

            if (read_data_A !== expected[addr_a]) begin
                $display(
                    "FAIL: Port A | Address=%0d | Expected=%h | Got=%h",
                    addr_a, expected[addr_a], read_data_A
                );
                errors = errors + 1;
            end

            if (read_data_B !== expected[addr_b]) begin
                $display(
                    "FAIL: Port B | Address=%0d | Expected=%h | Got=%h",
                    addr_b, expected[addr_b], read_data_B
                );
                errors = errors + 1;
            end
        end
    endtask


    initial begin

        clk = 1'b0;
        reset = 1'b0;
        write_enable = 1'b0;

        write_address = 5'd0;
        write_data = 32'd0;
        read_address_A = 5'd0;
        read_address_B = 5'd0;

        errors = 0;

        $display("======================================");
        $display(" REGISTER FILE TESTBENCH STARTED");
        $display("======================================");


        // TEST 1: Reset all registers
        $display("\nTEST 1: Reset");

        reset = 1'b1;

        repeat (2) @(posedge clk);
        #1;

        for (i = 0; i < 32; i = i + 1)
            expected[i] = 32'd0;

        @(negedge clk);
        reset = 1'b0;

        // Confirm that all 32 registers contain zero
        for (i = 0; i < 32; i = i + 1)
            check_reads(i, 31-i);


        // TEST 2: Write unique data into all 32 registers
        $display("\nTEST 2: Write all 32 registers");

        for (i = 0; i < 32; i = i + 1)
            write_reg(i, 32'hA500_0000 ^
                         (i * 32'h0101_0101));

        @(negedge clk);
        write_enable = 1'b0;

        $display("All 32 registers written.");


        // TEST 3: Read all registers using both ports
        $display("\nTEST 3: Read all registers");

        for (i = 0; i < 32; i = i + 1)
            check_reads(i, 31-i);


        // TEST 4: Writing must not occur when disabled
        $display("\nTEST 4: Write disabled");

        @(negedge clk);

        write_enable = 1'b0;
        write_address = 5'd5;
        write_data = 32'hDEAD_BEEF;

        read_address_A = 5'd5;
        read_address_B = 5'd6;

        @(posedge clk);
        #1;

        if (read_data_A !== expected[5]) begin
            $display("FAIL: Register 5 changed when writing was disabled.");
            errors = errors + 1;
        end

        if (read_data_B !== expected[6]) begin
            $display("FAIL: Register 6 changed unexpectedly.");
            errors = errors + 1;
        end


        // TEST 5: Overwrite register 5
        $display("\nTEST 5: Overwrite register");

        write_reg(5'd5, 32'h1234_5678);

        @(negedge clk);
        write_enable = 1'b0;

        check_reads(5'd5, 5'd6);


        // TEST 6: Reset must clear previously stored values
        $display("\nTEST 6: Reset after writing");

        @(negedge clk);
        reset = 1'b1;
        write_enable = 1'b0;

        @(posedge clk);
        #1;

        for (i = 0; i < 32; i = i + 1)
            expected[i] = 32'd0;

        @(negedge clk);
        reset = 1'b0;

        for (i = 0; i < 32; i = i + 1)
            check_reads(i, 31-i);


        // FINAL RESULT
        $display("\n======================================");

        if (errors == 0) begin
            $display("ALL REGISTER FILE TESTS PASSED");
        end
        else begin
            $display("TESTS FAILED: %0d mismatches", errors);
        end

        $display("Total mismatches = %0d", errors);
        $display("======================================");

        $finish;

    end

endmodule