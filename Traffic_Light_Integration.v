`timescale 1ns / 1ps

module Traffic_Light_Integrated (
    input  wire       clk,
    input  wire       clr,
    input  wire       SNS1,            // Sensor 1 for Road 1 vehicles
    input  wire       SNS2,            // Sensor 2 for Road 2 vehicles
    input  wire [7:0] db_level1,       // Sound decibel level Road 1
    input  wire [7:0] db_level2,       // Sound decibel level Road 2
    output reg  [5:0] lights           // [5:3] Road 1 (R,Y,G), [2:0] Road 2 (R,Y,G)
);

    // FSM State Encoding
    localparam [2:0] S0_R1_GRN   = 3'b000, // Road 1 Green, Road 2 Red
                     S1_R1_YEL   = 3'b001, // Road 1 Yellow, Road 2 Red
                     S2_ALL_RED1 = 3'b010, // All-Red Clearance
                     S3_R2_GRN   = 3'b011, // Road 1 Red, Road 2 Green
                     S4_R2_YEL   = 3'b100, // Road 1 Red, Road 2 Yellow
                     S5_ALL_RED2 = 3'b101; // All-Red Clearance

    // Timing Limits
    localparam [3:0] TIME_GREEN  = 4'd15;  // 15 clock cycles
    localparam [3:0] TIME_YELLOW = 4'd3;   // 3 clock cycles
    localparam [3:0] TIME_CLEAR  = 4'd2;   // 2 clock cycles

    // Siren Threshold
    localparam [7:0] SIREN_THRESHOLD_DB = 8'd85;

    reg [2:0] state;
    reg [3:0] count;

    wire siren1;
    wire siren2;

    assign siren1 = (db_level1 >= SIREN_THRESHOLD_DB);
    assign siren2 = (db_level2 >= SIREN_THRESHOLD_DB);

    // Sequential State and Counter Logic
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            state <= S0_R1_GRN;
            count <= 4'd0;
        end else begin
            // Emergency Ambulance Priority Management
            if (siren1 && !siren2) begin
                if (state == S3_R2_GRN) begin
                    state <= S4_R2_YEL;
                    count <= 4'd0;
                end else if (state == S4_R2_YEL && count >= TIME_YELLOW) begin
                    state <= S0_R1_GRN;
                    count <= 4'd0;
                end else if (state == S0_R1_GRN) begin
                    state <= S0_R1_GRN;
                    count <= 4'd0;
                end else begin
                    count <= count + 1'b1;
                end
            end else if (siren2 && !siren1) begin
                if (state == S0_R1_GRN) begin
                    state <= S1_R1_YEL;
                    count <= 4'd0;
                end else if (state == S1_R1_YEL && count >= TIME_YELLOW) begin
                    state <= S3_R2_GRN;
                    count <= 4'd0;
                end else if (state == S3_R2_GRN) begin
                    state <= S3_R2_GRN;
                    count <= 4'd0;
                end else begin
                    count <= count + 1'b1;
                end
            end else begin
                // Standard Timer and Sensor Sequence
                case (state)
                    S0_R1_GRN: begin
                        if ((count >= TIME_GREEN) && SNS2) begin
                            state <= S1_R1_YEL;
                            count <= 4'd0;
                        end else begin
                            state <= S0_R1_GRN;
                            if (count < TIME_GREEN)
                                count <= count + 1'b1;
                        end
                    end

                    S1_R1_YEL: begin
                        if (count >= TIME_YELLOW) begin
                            state <= S2_ALL_RED1;
                            count <= 4'd0;
                        end else begin
                            count <= count + 1'b1;
                        end
                    end

                    S2_ALL_RED1: begin
                        if (count >= TIME_CLEAR) begin
                            state <= S3_R2_GRN;
                            count <= 4'd0;
                        end else begin
                            count <= count + 1'b1;
                        end
                    end

                    S3_R2_GRN: begin
                        if ((count >= TIME_GREEN) && SNS1) begin
                            state <= S4_R2_YEL;
                            count <= 4'd0;
                        end else begin
                            state <= S3_R2_GRN;
                            if (count < TIME_GREEN)
                                count <= count + 1'b1;
                        end
                    end

                    S4_R2_YEL: begin
                        if (count >= TIME_YELLOW) begin
                            state <= S5_ALL_RED2;
                            count <= 4'd0;
                        end else begin
                            count <= count + 1'b1;
                        end
                    end

                    S5_ALL_RED2: begin
                        if (count >= TIME_CLEAR) begin
                            state <= S0_R1_GRN;
                            count <= 4'd0;
                        end else begin
                            count <= count + 1'b1;
                        end
                    end

                    default: begin
                        state <= S0_R1_GRN;
                        count <= 4'd0;
                    end
                endcase
            end
        end
    end

    // Combinational Output Logic
    always @(*) begin
        case (state)
            S0_R1_GRN:   lights = 6'b001100; // Road 1 Green, Road 2 Red
            S1_R1_YEL:   lights = 6'b010100; // Road 1 Yellow, Road 2 Red
            S2_ALL_RED1: lights = 6'b100100; // All Red Clearance
            S3_R2_GRN:   lights = 6'b100001; // Road 1 Red, Road 2 Green
            S4_R2_YEL:   lights = 6'b100010; // Road 1 Red, Road 2 Yellow
            S5_ALL_RED2: lights = 6'b100100; // All Red Clearance
            default:     lights = 6'b100100; // Safe Default: All Red
        endcase
    end

endmodule