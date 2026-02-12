module mdio_axi4lite (
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

    output mdc,
    inout mdio
);



endmodule