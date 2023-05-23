//////////////////////////////////////////////////////////////////////////////////

// Designer Name: Jason Farrell
// Create Date: 04/26/2023 03:08:41 PM
// EE4321 HDL
// Project Name: Final Project
// Module Name: IntegerAlu
// Instructor:  Mark Welker
// Description: The Alu which will perform all integer operations
//
// Inputs: Clk; nReset; nRead; nWrite; [15:0]address; [255:0]ExeDataOut
// Outputs: [255:0]IntDataOut
// Expected Result: This module will take the input from the Execution Engine to perform
//                  integer calculations based on what's required by the Execution Engine.      
// 
// Additional Comments: Code sourced with assistance provided by Mark Welker during class
//                      Edited to fulfill requirements of the final project within parameters
//                      performed by the Execution module.
/////////////////////////////////////////////////////////////////////////////////

// Alu Register setup // same register sequence for both ALU's 
//parameter AluStatusIn = 0;
//parameter AluStatusOut = 1;
//parameter ALU_Source1 = 2;
//parameter ALU_Source2 = 3;
//parameter ALU_Result = 4;
//parameter Overflow_err = 5;

module IntegerAlu(Clk,IntDataOut,ExeDataOut, address, nRead,nWrite, nReset);
//parameter OPCODE = 8'h 
parameter IntAdd = 8'h 10;
parameter IntSub = 8'h 11;
parameter IntMult = 8'h 12;
parameter IntDiv = 8'h 13;

// Inputs coming in from the TestInteger module
input logic Clk, nRead, nWrite, nReset;
input logic [15:0] address;
input logic [255:0] ExeDataOut;
// Output being sent back via bus to the TestInteger module
output logic [255:0] IntDataOut;
// To Trigger Status In/OUT
logic sIN, sOUT;
// Registers to store integers
reg [63:0] srcData1; 
reg [63:0] srcData2; 
reg [63:0] Result;

// Combinational logic to Trigger the Matrix ALU Module
always_comb begin
    if(address[15:12] == IntAlu)begin
        // Case statement to determine what logic to perform
        // First statements are determining which sources to store
        case(address[7:0])
            ALU_Source1:begin
                if(nWrite == 0)begin
                    srcData1  = ExeDataOut;
                    sOUT = 0;
                end
            end //end ALU_Source1
            
            ALU_Source2:begin
                if(nWrite == 0)begin
                    srcData2  = ExeDataOut;
                    sOUT = 0;
                end
            end //end ALU_Source2
            
            // For outputting the result
            ALU_Result:begin
                if(nRead == 0) IntDataOut = Result;
            end //End ALU_Result
            
            // To Alert the Execution engine that operations are finished.
            AluStatusOut:begin
                if(nRead == 0) IntDataOut = sOUT;
            end // End AluStatusOut
            
            // To Alert the Execution engine that operations are being fulfilled.
            AluStatusIn:begin
                if(nWrite == 1)begin
                    //sIN = ExeDataOut;
                    case(ExeDataOut[7:0])
                        IntAdd:
                            Result = srcData1 + srcData2;
                        IntSub:
                            Result = srcData1 - srcData2;
                        IntMult:
                            Result = srcData1 * srcData2;
                        IntDiv:
                            Result = srcData2 / srcData1;

                    endcase //End Case: sIN
                sOUT = 1;    
                end //End IF: nWrite == 1
            end //End AluStatusIn
        endcase //End Case: address[7:0]
    end //End IF: address[15:12]
end //End always_comb

endmodule