//////////////////////////////////////////////////////////////////////////////////

// Designer Name: Jason Farrell
// Create Date: 04/26/2023 03:08:41 PM
// EE4321 HDL
// Project Name: Final Project
// Module Name: MatrixAlu
// Instructor:  Mark Welker
// Description: The Alu which will perform all matrix operations
//
// Inputs: Clk; nReset; nRead; nWrite; [15:0]address; [255:0]ExeDataOut
// Outputs: [255:0]MatrixDataOut
// Expected Result: This module will take the input from the Execution Engine to perform
//                  matrix calculations based on what's required by the Execution Engine.      
// 
// Additional Comments: Code sourced with assistance provided by Mark Welker during class
//                      Edited to fulfill requirements of the final project within parameters
//                      performed by the Execution module. Assistance from Jeff and Carson
//                      to complete MMult3. 
/////////////////////////////////////////////////////////////////////////////////

// Alu Register setup // same register sequence for both ALU's 
//parameter AluStatusIn = 0;
//parameter AluStatusOut = 1;
//parameter ALU_Source1 = 2;
//parameter ALU_Source2 = 3;
//parameter ALU_Result = 4;
//parameter Overflow_err = 5;

module MatrixAlu(Clk,MatrixDataOut,ExeDataOut, address, nRead,nWrite, nReset);

// All parameters to perform specific functions with matrices based on Final Project
parameter MMult1 = 8'h 00;
parameter MMult2 = 8'h 01;
parameter MMult3 = 8'h 02;
parameter Madd = 8'h 03;
parameter Msub = 8'h 04;
parameter Mtranspose = 8'h 05;
parameter MScale = 8'h 06;
parameter MScaleImm = 8'h 07;


// All input/outputs for the module
input logic Clk, nRead, nWrite, nReset;
input logic [15:0] address;
input logic [255:0] ExeDataOut;
output logic [255:0] MatrixDataOut;
// To Trigger Status In/OUT
logic sIN, sOUT;
// Registers to store the matrices (4x4x16)
reg [3:0][3:0][15:0] srcData1;
reg [3:0][3:0][15:0] srcData2;
reg [3:0][3:0][15:0] Result;

// Combinational logic to Trigger the Matrix ALU Module
always_comb begin
    if(address[15:12] == AluEn)begin
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
                if(nRead == 0) MatrixDataOut = Result;
            end //End ALU_Result
            
            // To Alert the Execution engine that operations are finished.
            AluStatusOut:begin
                if(nRead == 0) MatrixDataOut = sOUT;
            end // End AluStatusOut
            
            // To Alert the Execution engine that operations are being fulfilled.
            AluStatusIn:begin
                if(nWrite == 1)begin
                    //sIN = ExeDataOut;
                    Result = 0;
                    case(ExeDataOut[7:0])
                        //4x4 * 4x4
                        MMult1:begin
                            for(int ROW = 0; ROW < 4; ROW++)begin
                                for(int COL = 0; COL < 4; COL++)begin
                                    Result[ROW][COL] = 0;
                                    for(int k = 0; k < 4; k++)begin
                                        Result[ROW][COL] += srcData1[ROW][k] * srcData2[k][COL];
                                    end 
                                end
                            end
                        end //End MMult1
                        //4x2 * 2x4
                        MMult2:begin
                            for(int row = 0; row < 4; row++)begin
                                for(int col = 0; col < 4; col++)begin
                                    Result[row][col] = 0;
                                    for(int k = 0; k < 2; k++)begin
                                        Result[row][col] += srcData1[row][k] * srcData2[k][col];
                                    end 
                                end
                            end
                        end //End MMult2
                        
                        // 2x4 * 4x2
                        MMult3:begin
                            for(int i = 0; i < 2; i ++)begin
                                for(int j = 0; j < 2; j++)begin
                                    for(int k = 0; k < 4; k++)begin
                                        Result[i][j] = Result[i][j] + (srcData1[i][k] * srcData2[k][j]);    
                                    end
                                end
                            end
                            //Set all data up to the final 2x2 to 0
                            Result[255:64] = 0;
                            // Format the Matrix
                            Result[0][3:2]= Result[1][1:0];
                            Result[1][1:0] = 0;
                        end //End MMult3
                        
                        Madd: begin
                            for(int row = 0; row < 4; row++)begin
                                for(int col = 0; col < 4; col++)begin
                                    Result[row][col] = srcData1[row][col] + srcData2[row][col];
                                end
                            end
                        end //End Madd
                        
                        Msub:begin
                            for(int row = 0; row < 4; row++)begin
                                for(int col = 0; col < 4; col++)begin
                                    Result[row][col] = srcData1[row][col] - srcData2[row][col];
                                end
                            end //End Msub
                        end
                        
                        Mtranspose:begin
                            Result = 0;
                            for(int row = 0; row < 4; row++)begin
                                for(int col = 0; col < 4; col++)begin
                                    Result[row][col] = srcData1[col][row];
                                end
                            end
                        end //End Mtranspose
                        
                        MScale:begin
                            for(int row = 0; row < 4; row++)begin
                                for(int col = 0; col < 4; col++)begin
                                    Result[row][col] = srcData1[row][col] * srcData2;
                                end
                            end
                        end //End MScale
                        
                        MScaleImm:begin
                            for(int row = 0; row < 4; row++)begin
                                for(int col = 0; col < 4; col++)begin
                                    Result[row][col] = srcData1[row][col] * srcData2;
                                end
                            end
                        end //End MSMScaleImmcale
                    endcase //End Case: sIN 
                    sOUT = 1;
                end //End IF: nWrite == 1
            end //End AluStatusIn                    
        endcase //End Case: address[7:0]
    end //End IF: address[15:12]
end //End always_comb
endmodule
