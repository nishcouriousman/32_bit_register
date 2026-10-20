module dff(
    input d,
    input clk,
    input ena,
    input reset,
    output reg q
);
always @(posedge clk)
begin
    if (reset == 1'b1)
    q <= 1'b0;
    else if  (ena == 1'b1)
        q <= d;
    
end
endmodule
module register_32(
    input [31:0]d_in,
    input reset,
    input clk,
    input enable,
    output [31:0] q_out

);
genvar i;
generate
    for (i = 0; i < 32; i = i + 1)
    begin
    dff dff_in1(.d(d_in[i]), .reset(reset), .clk(clk), .ena(enable), .q(q_out[i]));
    end
    endgenerate
endmodule
module register_file(
    input clk,
    input reset,
    input write_enable,
    input [4:0] write_address,
    input [31:0] write_data,
    input [4:0] read_address_A,
    input [4:0] read_address_B,
    output [31:0] read_data_A,
    output [31:0] read_data_B
);
wire [31:0] enable;
genvar i;
generate
    for (i = 0; i < 32; i = i + 1)
    begin
        assign enable[i] = (write_address == i); 
    end
endgenerate

wire [31:0] register_output [31:0];
mux mux_A(.in(register_output), .select(read_address_A), .out(read_data_A));
mux mux_B(.in(register_output), .select(read_address_B), .out(read_data_B));
genvar j;
generate
    for (j = 0; j < 32; j = j + 1)
    begin
        register_32 register_instance (.d_in(write_data), .reset(reset), .clk(clk), .enable(write_enable & enable[j]), .q_out(register_output[j]));
    end
endgenerate

endmodule
module mux(
    input [31:0] in [31:0],
    input [4:0] select,
    output [31:0] out
);
wire [31:0] mux_out [31:0];
wire [31:0] mux_or [31:0];
genvar k;
generate
    for (k = 0; k < 32; k = k + 1)
    begin
        assign mux_out[k] = (select == k) ? in[k] : 32'b0 ;
    end
endgenerate
assign mux_or[0] = mux_out[0];
genvar l;
generate
    for(l = 1; l < 32; l = l + 1)
    begin
        assign mux_or[l] = mux_or[l-1] | mux_out[l];
    end
endgenerate
assign out = mux_or[31];
endmodule