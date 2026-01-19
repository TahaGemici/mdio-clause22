module mdio_clause22 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        mdio_start,
    input  wire [4:0]  phy_addr,
    input  wire [4:0]  reg_addr,
    input  wire [15:0] wr_data,
    input  wire        mdio_rw,      // 1: write, 0: read
    output reg         mdio_busy,
    output reg  [15:0] rd_data,
    output reg         mdio_done,
    output wire        mdio_mdc,
    inout  wire        mdio_mdio
);

    // MDIO clock generation
    reg [7:0] clk_div;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div <= 8'd0;
        else
            clk_div <= clk_div + 8'd1;
    end
    assign mdio_mdc = clk_div[7]; // Divide clock for MDC

    // MDIO state machine
    localparam IDLE       = 3'd0;
    localparam PREAMBLE   = 3'd1;
    localparam START      = 3'd2;
    localparam OP         = 3'd3;
    localparam ADDR       = 3'd4;
    localparam TURNAROUND = 3'd5;
    localparam DATA       = 3'd6;
    localparam DONE       = 3'd7;

    reg [2:0] state, next_state;
    reg [4:0] bit_cnt;
    reg       mdio_out_en;
    reg       mdio_out;
    reg [15:0] data_shift;

    // State transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (mdio_start)
                    next_state = PREAMBLE;
            end
            PREAMBLE: begin
                if (bit_cnt == 5'd31)
                    next_state = START;
            end
            START: begin
                next_state = OP;
            end
            OP: begin
                next_state = ADDR;
            end
            ADDR: begin
                if (bit_cnt == 5'd9)
                    next_state = TURNAROUND;
            end
            TURNAROUND: begin
                next_state = DATA;
            end
            DATA: begin
                if (bit_cnt == 5'd15)
                    next_state = DONE;
            end
            DONE: begin
                next_state = IDLE;
            end
        endcase
    end
    // Bit counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bit_cnt <= 5'd0;
        else if (state != next_state)
            bit_cnt <= 5'd0;
        else if (state != IDLE)
            bit_cnt <= bit_cnt + 5'd1;
    end
    // MDIO output control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mdio_out_en <= 1'b0;
            mdio_out    <= 1'b1;
            rd_data     <= 16'd0;
            mdio_busy   <= 1'b0;
            mdio_done   <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    mdio_out_en <= 1'b0;
                    mdio_out    <= 1'b1;
                    mdio_busy   <= 1'b0;
                    mdio_done   <= 1'b0;
                end
                PREAMBLE: begin
                    mdio_out_en <= 1'b1;
                    mdio_out    <= 1'b1; // Send preamble '1's
                    mdio_busy   <= 1'b1;
                end
                START: begin
                    mdio_out    <= 1'b0; // Start bits '01'
                end
                OP: begin
                    mdio_out    <= mdio_rw ? 1'b1 : 1'b0; // OP code
                end
                ADDR: begin
                    if (bit_cnt < 5'd5)
                        mdio_out <= phy_addr[4 - bit_cnt];
                    else
                        mdio_out <= reg_addr[9 - bit_cnt];
                end
                TURNAROUND: begin
                    if (mdio_rw)
                        mdio_out <= 1'bz; // Release for write turnaround
                    else
                        mdio_out <= 1'bz; // Release for read turnaround
                end
                DATA: begin
                    if (mdio_rw) begin
                        mdio_out <= wr_data[15 - bit_cnt]; // Write data
                    end else begin
                        rd_data[15 - bit_cnt] <= mdio_mdio; // Read data
                    end
                end
                DONE: begin
                    mdio_out_en <= 1'b0;
                    mdio_done   <= 1'b1;
                end
            endcase
        end
    end
    // MDIO bidirectional control
    assign mdio_mdio = mdio_out_en ? mdio_out : 1'bz;
endmodule