module mdio_clause22(
    input clk, // 100 MHz
    input arst_n,

    input start,
    input[9:0] addr, // {phy_addr[4:0], reg_addr[4:0]}
    input[15:0] wr_data,
    input write,

    output reg done,
    output reg[15:0] rd_data,

    output mdc,
    inout mdio // requires pull-up resistor
);
    clk_div #(.DIV_FACTOR(100)) mdc_init (.clk_in(clk), .arst_n(arst_n), .clk_out(mdc));

    reg mdio_out, mdio_out_nxt, done_nxt;
    assign mdio = mdio_out ? 1'bz : 1'b0;
    
    reg[2:0] state, state_nxt;
    reg[4:0] counter, counter_nxt;
    reg[15:0] rd_data_nxt;
    always @(posedge mdc or negedge arst_n) begin
        if(!arst_n) begin
            done <= 1'b0;
            state <= 0;
            counter <= 0;
            mdio_out <= 1'b1;
            rd_data <= 16'd0;
        end else begin
            done <= done_nxt;
            state <= state_nxt;
            counter <= counter_nxt;
            mdio_out <= mdio_out_nxt;
            rd_data <= rd_data_nxt;
        end
    end

    localparam IDLE       = 3'd0;
    localparam PREAMBLE   = 3'd1;
    localparam START      = 3'd2;
    localparam OP         = 3'd3;
    localparam ADDR       = 3'd4;
    localparam TURNAROUND = 3'd5;
    localparam DATA       = 3'd6;
    localparam DONE       = 3'd7;
    always @* begin
        done_nxt = 1'b0;
        state_nxt = state;
        counter_nxt = counter + 1;
        mdio_out_nxt = 1'b1;
        rd_data_nxt = rd_data;
        case(state)
            IDLE: begin
                counter_nxt = 0;
                state_nxt = start ? PREAMBLE : state;
            end
            PREAMBLE: begin
                if(counter == 31) begin
                    state_nxt = START;
                end
            end
            START: begin
                mdio_out_nxt = counter[0];
                state_nxt = counter[0] ? OP : state;
            end
            OP: begin
                mdio_out_nxt = write ? counter[0] : (~counter[0]);
                state_nxt = counter[0] ? ADDR : state;
            end
            ADDR: begin
                mdio_out_nxt = addr[13 - counter];
                if(counter == 13) begin
                    state_nxt = TURNAROUND;
                end
            end
            TURNAROUND: begin
                if(write) begin
                    mdio_out_nxt = ~counter[0];
                end
                state_nxt = counter[0] ? DATA : state;
            end
        endcase
    end

endmodule