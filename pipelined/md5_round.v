module md5_round (
    input clk,
    input [127:0] cur_in,
    input [31:0] w_i,
    input [31:0] k_i,
    input [4:0] s_i,
    input [1:0] f_op,
    output [127:0] cur_out
);

wire [31:0] a, b, c, d;
assign {a, b, c, d} = cur_in;

reg [31:0] f_result;
always @* begin
    case (f_op)
        2'b00: f_result = (b & c) | (~b & d);
        2'b01: f_result = (d & b) | (~d & c);
        2'b10: f_result = b ^ c ^ d;
        2'b11: f_result = c ^ (b | ~d);
    endcase
end

wire [31:0] sum = (a + f_result) + (w_i + k_i);
wire [31:0] lc_shift = (sum << s_i) | (sum >> (32 - s_i));
wire [31:0] new_b = b + lc_shift;

reg [127:0] next_state;
assign cur_out = next_state;
always @(posedge clk) begin
    next_state <= {d, new_b, b, c};
end

endmodule