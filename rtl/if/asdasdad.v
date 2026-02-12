module morse_axi4lite (
    input aclk,
    input aresetn,

    input awvalid,
    output awready,
    input[31:0] awaddr,
    input[2:0] awprot,

    input wvalid,
    output wready,
    input[31:0] wdata,
    input[3:0] wstrb,

    output bvalid,
    input bready,
    output[1:0] bresp,

    input arvalid,
    output arready,
    input[31:0] araddr,
    input[2:0] arprot,

    output rvalid,
    input rready,
    output[31:0] rdata,
    output[1:0] rresp,

    output morse_out
);
    // memory-mapped registers
    reg[31:0] prescaler, prescaler_nxt;

    wire full, empty;
    morse morse_inst (
        .clk(aclk),
        .arst_n(aresetn),

        .write_en(wr_slv_en[0] & (wr_slv_addr[3:2] == 2'd2)),
        .ascii_in(wr_slv_data[7:0]),
        .prescaler(prescaler),
        .full(full),
        .empty(empty),

        .morse_out(morse_out)
    );

    wire[3:0] wr_slv_en;
    wire[31:0] wr_slv_addr, wr_slv_data;
    axi4lite_write_slave write_slave_inst (
        .aclk(aclk),
        .aresetn(aresetn),

        .awvalid(awvalid),
        .awready(awready),
        .awaddr(awaddr),
        .awprot(awprot),

        .wvalid(wvalid),
        .wready(wready),
        .wdata(wdata),
        .wstrb(wstrb),

        .bvalid(bvalid),
        .bready(bready),
        .bresp(bresp),

        .stall(full & (wr_slv_addr[3:2] == 2'd2)),
        .en(wr_slv_en),
        .addr(wr_slv_addr),
        .data(wr_slv_data)
    );

    reg[31:0] read_mux_out;
    axi4lite_read_slave read_slave_inst (
        .aclk(aclk),
        .aresetn(aresetn),

        .arvalid(arvalid),
        .arready(arready),
        .araddr(araddr),
        .arprot(arprot),

        .rvalid(rvalid),
        .rready(rready),
        .rdata(rdata),
        .rresp(rresp),

        .stall(1'b0),
        .data(read_mux_out)
    );

    always @(posedge aclk or negedge aresetn) begin
        if(~aresetn) begin
            prescaler <= 0;
        end else begin
            prescaler <= prescaler_nxt;
        end
    end
    always @* begin
        prescaler_nxt = prescaler;
        if(wr_slv_addr[3:2] == 2'd0) begin
            if(wr_slv_en[0]) prescaler_nxt[7:0] = wr_slv_data[7:0];
            if(wr_slv_en[1]) prescaler_nxt[15:8] = wr_slv_data[15:8];
            if(wr_slv_en[2]) prescaler_nxt[23:16] = wr_slv_data[23:16];
            if(wr_slv_en[3]) prescaler_nxt[31:24] = wr_slv_data[31:24];
        end
        
        case(araddr[3:2])
            2'd0: read_mux_out = prescaler;
            2'd1: read_mux_out = {30'b0, full, empty};
            default: read_mux_out = 0;
        endcase
    end

endmodule