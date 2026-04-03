module md5_top (
    input clk,
    input [511:0] msg,
    input msg_valid,
    output [127:0] hash,
    output hash_valid
);

reg [31:0] K [0:63];
reg [4:0] S [0:63];
reg [3:0] W_index [0:63];

initial begin
    $readmemh("K_constants.hex", K);
    $readmemb("S_constants.bin", S);
    $readmemh("W_constants.hex", W_index);
end

reg [511:0] msg_pipe [0:63];
integer j;
always @(posedge clk) begin
    j = 32'bx;
    msg_pipe[0] <= msg;
    for (j = 0; j < 63; j = j + 1)
        msg_pipe[j+1] <= msg_pipe[j];
end

reg [127:0] hash_pipe [0:64];
integer k;
always @(posedge clk) begin
    k = 32'bx;
    hash_pipe[0] <= {32'h67452301, 32'hEFCDAB89, 32'h98BADCFE, 32'h10325476};
    for (k = 0; k < 64; k = k + 1)
        hash_pipe[k+1] <= hash_pipe[k];
end

wire [127:0] pipeline_net [0:64];
assign pipeline_net[0] = hash_pipe[0];

genvar i;
generate
    for (i = 0; i < 64; i = i + 1) begin: MD5_ROUNDS
        wire [31:0] W_i = msg_pipe[i][511 - (W_index[i]*32) -: 32];
        wire [31:0] W_efix = {W_i[7:0], W_i[15:8], W_i[23:16], W_i[31:24]};

        md5_round round_inst (
            .clk(clk),
            .cur_in(pipeline_net[i]),
            .w_i(W_efix),
            .k_i(K[i]),
            .s_i(S[i]),
            .f_op(i[5:4]),
            .cur_out(pipeline_net[i + 1])
        );
    end
endgenerate

reg [64:0] valid_pipe;
assign hash_valid = valid_pipe[64];
always @(posedge clk) begin
    valid_pipe <= {valid_pipe[63:0], msg_valid};
end

wire [31:0] A_final = pipeline_net[64][127:96] + hash_pipe[64][127:96];
wire [31:0] B_final = pipeline_net[64][95:64]  + hash_pipe[64][95:64];
wire [31:0] C_final = pipeline_net[64][63:32]  + hash_pipe[64][63:32];
wire [31:0] D_final = pipeline_net[64][31:0]   + hash_pipe[64][31:0];

assign hash[127:96] = {A_final[7:0], A_final[15:8], A_final[23:16], A_final[31:24]};
assign hash[95:64] = {B_final[7:0], B_final[15:8], B_final[23:16], B_final[31:24]};
assign hash[63:32] = {C_final[7:0], C_final[15:8], C_final[23:16], C_final[31:24]};
assign hash[31:0] = {D_final[7:0], D_final[15:8], D_final[23:16], D_final[31:24]};

endmodule