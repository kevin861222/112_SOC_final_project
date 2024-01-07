/* BRAM 
latency = 10 T 
burst = no
continuous read / write = 1
*/

module bram(
    CLK,
    WE,
    EN,
    Di,
    Do,
    A
);

    input   wire            CLK;
    input   wire            WE;
    input   wire            EN;
    input   wire    [31:0]  Di;
    output  reg     [31:0]  Do;
    input   wire    [12:0]   A;

    // 128 kB
    parameter N = 13 ;
    (* ram_style = "block" *) reg [31:0] RAM[0:2**N-1];

    always @(posedge CLK)
        if(EN) begin
            Do <= RAM[A];
            if(WE) begin
                RAM[A] <= Di;
            end
        end
        else
            Do <= 32'b0;
endmodule
