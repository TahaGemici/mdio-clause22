module mdio (
    input clk,
    input arst_n,

    input[31:0] prescaler,
    input mode, // 0: clause22, 1: clause45
    
    input start,
    output reg done,

    input[11:0] conf, // {op, phy_addr, reg/dev_addr}
    input[15:0] wr_data,
    output reg[15:0] rd_data,

    output mdc,
    inout mdio // add pull-up resistor if needed
);
    clk_div mdc_init (
        .clk_in(clk),
        .arst_n(arst_n),
        .prescaler(prescaler),
        .clk_out(mdc)
    );

    reg mdio_out, mdio_out_nxt, done_nxt;
    assign mdio = mdio_out ? 1'bz : 1'b0;
    
    reg[2:0] state, state_nxt;
    reg[4:0] counter, counter_nxt;
    reg[15:0] rd_data_nxt;
    always @(negedge mdc or negedge arst_n) begin
        if(!arst_n) begin
            done <= 1'b0;
            state <= 0;
            counter <= 0;
            mdio_out <= 1'b1;
        end else begin
            done <= done_nxt;
            state <= state_nxt;
            counter <= counter_nxt;
            mdio_out <= mdio_out_nxt;
        end
    end
    always @(posedge mdc or negedge arst_n) begin
        if(!arst_n) begin
            rd_data <= 16'd0;
        end else begin
            rd_data <= rd_data_nxt;
        end
    end

    localparam IDLE       = 3'd0;
    localparam PREAMBLE   = 3'd1;
    localparam START      = 3'd2;
    localparam CONF       = 3'd3;
    localparam TURNAROUND = 3'd4;
    localparam DATA       = 3'd5;
    localparam DONE       = 3'd6;
    always @* begin
        done_nxt = done;
        state_nxt = state;
        counter_nxt = counter - 1;
        mdio_out_nxt = 1'b1;
        rd_data_nxt = rd_data;
        case(state)
            IDLE: begin
                counter_nxt = 0;
                if(start) begin
                    state_nxt = PREAMBLE;
                    done_nxt = 1'b0;
                end
            end
            PREAMBLE: begin
                if(counter == 1) begin
                    state_nxt = START;
                end
            end
            START: begin
                mdio_out_nxt = counter[0] & (~mode);
                if(counter[0]) begin
                    state_nxt = CONF;
                    counter_nxt = 11;
                end
            end
    input mode, // 0: clause22, 1: clause45
    
    input start,
    output reg done,

    input[11:0] conf, // {op, phy_addr, reg/dev_addr}
    input[15:0] wr_data,
    output reg[15:0] rd_data,
            CONF: begin
                mdio_out_nxt = conf[counter];
                if(counter == 0) begin
                    state_nxt = TURNAROUND;
                    counter_nxt = {4'h00, op[0]};
                end
            end
            TURNAROUND: begin
                counter_nxt = counter + 1;
                if(op[0]) begin
                    mdio_out_nxt = counter[0];
                end
                if(counter[1]) begin
                    counter_nxt = 15;
                    state_nxt = DATA;
                end
            end
            DATA: begin
                mdio_out_nxt = op[0] ? wr_data[counter] : 1'b1;
                if(op[1]) begin
                    rd_data_nxt[counter] = mdio;
                end
                if(counter == 0) begin
                    state_nxt = DONE;
                    done_nxt = 1'b1;
                end
            end
            DONE, default: begin
                state_nxt = IDLE;
            end
        endcase
    end

endmodule