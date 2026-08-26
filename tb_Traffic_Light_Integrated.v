`timescale 1ns / 1ps

module tb_Traffic_Light_Integrated;

    reg        clk;
    reg        clr;
    reg        SNS1;
    reg        SNS2;
    reg  [7:0] db_level1;
    reg  [7:0] db_level2;
    wire [5:0] lights;

    // Instantiate Unit Under Test (UUT)
    Traffic_Light_Integrated uut (
        .clk(clk),
        .clr(clr),
        .SNS1(SNS1),
        .SNS2(SNS2),
        .db_level1(db_level1),
        .db_level2(db_level2),
        .lights(lights)
    );

    // Clock Generation: 20ns period (50 MHz)
    always #10 clk = ~clk;

    initial begin
        // Waveform dump configuration
        $dumpfile("traffic_integrated.vcd");
        $dumpvars(0, tb_Traffic_Light_Integrated);

        // 1. Initial State & Power-on Reset
        clk = 0;
        clr = 1;
        SNS1 = 0;
        SNS2 = 0;
        db_level1 = 8'd40; // Ambient noise level
        db_level2 = 8'd42;
        #50;
        clr = 0;

        // 2. Normal Demand: Car arrives on Road 2
        #100;
        SNS2 = 1;
        #350; // Allow transition through S0 -> S1 -> S2 -> S3
        SNS2 = 0;

        // 3. Ambulance Preemption: Siren detected on Road 1 (95 dB)
        #100;
        db_level1 = 8'd95;
        #120; // Preempts Road 2 to Yellow, then switches Road 1 to Green

        // Ambulance clears intersection
        db_level1 = 8'd45;

        // 4. Normal sensor cycle resumes
        #100;
        SNS2 = 1;
        #250;
        SNS2 = 0;

        #200;
        $finish;
    end

endmodule