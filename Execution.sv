//////////////////////////////////////////////////////////////////////////////////

// Designer Name: Jason Farrell
// Create Date: 04/26/2023 03:08:41 PM
// EE4321 HDL
// Project Name: Final Project
// Module Name: Execution
// Instructor:  Mark Welker
// Description: The Execution Engine; this will provide all the data to each module to execute
//              what's required by the program. 
//
// Inputs: Clk, nReset, [255:0]InstructionDataOut, [255:0]MemDataOut; [255:0]MatrixDataOut; [255:0]IntDataOut
// Outputs:  nRead, nWrite, [15:0]address, [255:0]ExeDataOut
// Expected Result: This module will receive instructions from the Instruct module to determine 
//                  which actions to perform (opCode). Then this module will use the instruction data
//                  to locate source 1, source 2, and where to store the via destination location provided. 
//                  This module will then output instructions to the specified module to perform its calculations,
//                  wait for the data to be relayed back, and store the data to the memory or a internal register.     
// 
// Additional Comments: Logic of code sourced with permission from Jesus Rivera III.
//                      Edits were made and new logic provided by Jason Farrell to 
//                      fulfill project requirements such as memory location modules, and status in/out.
/////////////////////////////////////////////////////////////////////////////////

// Alu Register setup // same register sequence for both ALU's 
//parameter AluStatusIn = 0;
//parameter AluStatusOut = 1;
//parameter ALU_Source1 = 2;
//parameter ALU_Source2 = 3;
//parameter ALU_Result = 4;
//parameter Overflow_err = 5;

module Execution (Clk,InstructDataOut,MemDataOut,MatrixDataOut,IntDataOut,ExeDataOut, address, nRead,nWrite, nReset);

    //States fpr the Execution Engine
    parameter  Fetch = 0;
    parameter  Decode = 1;
    parameter  Execute = 2;
    parameter  Clear = 3;
    // Parameters for OpCode
    // Instruction: OpCode :: dest :: src1 :: src2 Each section is 8 bits.
    parameter Stop = 8'h FF;  //Stop the processer //Stop::FFh::00::00::00
    parameter MMult1 = 8'h 00; //MMult::00h::Reg/mem::Reg/mem::Reg/mem
    parameter MMult2 = 8'h 01; //MMult::00h::Reg/mem::Reg/mem::Reg/mem
    parameter MMult3 = 8'h 02; //MMult::00h::Reg/mem::Reg/mem::Reg/mem
    parameter Madd = 8'h 03; //Madd::01h::Reg/mem::Reg/mem::Reg/mem
    parameter Msub = 8'h 04; //Msub::02h::Reg/mem::Reg/mem::Reg/mem
    parameter Mtranspose = 8'h 05; //Mtranspose::03h::Reg/mem::Reg/mem::Reg/mem
    parameter MScale = 8'h 06; //MScale::04h::Reg/mem::Reg/mem::Reg/mem
    parameter MScaleImm = 8'h 07; //MScaleImm::05h:Reg/mem::Reg/mem::Immediate
    parameter IntAdd = 8'h 10; //IntAdd::10h::Reg/mem::Reg/mem::Reg/mem
    parameter IntSub = 8'h 11; //IntSub::11h::Reg/mem::Reg/mem::Reg/mem
    parameter IntMult = 8'h 12; //IntMult::12h::Reg/mem::Reg/mem::Reg/mem
    parameter IntDiv = 8'h 13; //IntDiv::13h::Reg/mem::Reg/mem::Reg/mem

    // Inputs & Outputs
   	output logic nRead,nWrite;             //Generated data for read and write actions
	output logic [15:0] address;           //Generated data during Execution
	output logic [255:0] ExeDataOut;       //Output data from Execution Engine
	input logic nReset,Clk;                //Data from Test Bench
	input logic [255:0] InstructDataOut;   //Data from Instruct module
	input logic [255:0] MatrixDataOut;     //Data from the MatrixAlu module
	input logic [255:0] IntDataOut;        //Data from the IntergerAlu module
	input logic [255:0] MemDataOut;        //Data from Main Memory module
	logic [7:0] clkCount;	               //Counts through clock cycle for executing instructions
	
	
	reg [7:0] PC;	                       //Program counter for which Instruction Mem to use
	reg [31:0] opCode;	                   //Op Code in to easily access which bits to use from Instruciton Mem
	reg [7:0] operation;                   //Which operation to perform
	reg [15:0] destAddress;                 //Determined by opcode; where data will be stored in Memory
	reg [15:0] srcAddress1;                 //Determined by opcode; address to first source to be manipulated
	reg [15:0] srcAddress2;                 //Determined by opcode; address to second source to be manipulated
	reg [255:0] srcData1;                  //Data sourced by srcAddress1 from MainMemory
	reg [255:0] srcData2;	               //Data sourced by secAddress2 from MainMemory
	reg [255:0] Result;                    //The result of the mainpulated sourceData 1&2
	reg [255:0] InternalReg [3];           //Internal Registers for internal storage
	reg [3:0] currentState;                // What state we're on
	reg [3:0] nextState;                   // The next state to go to
	logic done;                            // If the current state is complete then trigger the next state
	                                       
	
	// Reset Condition; asynchronous negedge reset
	always_ff @(posedge Clk or negedge nReset) begin
	   if(~nReset)begin
	       nRead <= 1;
	       nWrite <= 1;
	       address <= 0;
	       ExeDataOut <= 256'b x;
	       opCode <= 0;
	       operation <= 0;
	       srcData1 <= 0;
	       srcData2 <= 0;
	       Result <= 0;
	       srcAddress1 <= 0;
	       srcAddress2 <= 0;
	       destAddress <= 0;
	       clkCount <= 0;
	       PC <= 0;
	       InternalReg[0] <= 0;
	       InternalReg[1] <= 0;
	       InternalReg[2] <= 0;
	       done <= 0;
	       currentState <= 0;
	   end //end nReset
	end    //end always_ff (Clk nReset)
	// Main Execution Engine
    always_ff @ (posedge Clk)begin
        // While reset is high and program not done
        if(nReset != 0 && done == 0)begin
            // Check for clkCount to fetch instructions.
            if(clkCount == 0)begin
                currentState = Fetch;
            end // End if clkCount == 0
            
            // Case statement for State
            case(currentState)
                Fetch:begin
                    // Couting clocks
                    case(clkCount)
                    0:begin
                        nRead <= 0;
                        nWrite <= 1;
                        // Instruction memory fetch based on program counter to cycle through instructions
                        address <= 16'h 2000 + PC;
                    end //end 0
                    1:begin
                        // Read instruction Data 
                        opCode <= InstructDataOut[31:0];
                    end //end 1
                    
                    2:begin
                        // End Read; change state and reset clock
                        nRead <= 1;
                        currentState <= Decode;
                        //clkCount = 0;
                    end //end 2
                    
                   endcase //end Case: clkCount 
                   // So no clock cycles will start back at 0 as to not cross any data flow
                clkCount++;   
                end //End Fetch
                
                Decode:begin
                    // Which operation based on most significant bits of opCode
                    operation <= opCode[31:24];
                    // Determine if internal registers or main memory
                    if(opCode[20] == 1)begin
                        destAddress <= 16'h 1000 + opCode[19:16];
                    end 
                    else destAddress <= opCode[23:16];
                    // Determine if source 1 is internal register or main memory
                    if(opCode[12] == 1)begin
                        srcAddress1 <= 16'h 1000 + opCode[11:8];
                    end 
                    else srcAddress1 <= opCode[15:8];
                    // Determine if source 2 is internal register or main memory
                    if(opCode[4] == 1)begin
                        srcAddress2 <= 16'h 1000 + opCode[3:0];
                    end 
                    else srcAddress2 <= opCode[7:0];
                    // Move to Execute; don't let clkCount go to 0
                    currentState <= Execute;
                    clkCount <= 1;
                end // End Decode
                
                Execute:begin
                    case(operation)
                       Stop:begin
                            $stop;
                        end // End Stop
                        
                        MMult1:begin
                            case(clkCount)
                                1:begin
                                    //Read in source 1 from Memory
                                    nRead <= 0;
                                    address <= 16'h 0000 + srcAddress1;
                                end //end 1
                                
                                2:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData1 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData1 <= InternalReg[address[11:0]];
                                    // For source data 2
                                    address <= 16'h 0000 + srcAddress2;
                                end //end 2
                                
                                3:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData2 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData2 <= InternalReg[address[11:0]];
                                    //end Read
                                    nRead <= 1;
                                end //end 3
                                
                                4:begin
                                    // Write data to Matrix ALU
                                    // Source 1:
                                    address <= 16'h 3002;
                                    ExeDataOut <= srcData1;
                                    nWrite <= 0;
                                end //end 4
                                
                                6:begin
                                // Source 2:
                                    address <= 16'h 3003;
                                    ExeDataOut <= srcData2;
                                end //end 6
                                
                                7:begin
                                    // End Write
                                    nWrite <= 1;
                                    // Signal Status In: Matrix will perform MMult1
                                    address <= 16'h 3000;
                                    ExeDataOut <= MMult1;
                                end //end 7
                                
                                8:begin
                                    nRead <= 0;
                                    address <= 16'h 3001;
                                end //end 8
                                
                                9:begin
                                    // Obtain result
                                    // Wait for Status out by Matrix ALU
                                    if(MatrixDataOut != 1) wait(MatrixDataOut == 1);
                                    else address <= 16'h 3004;
                                end //end 9
                                
                                11:begin
                                    // Set result
                                    Result <= MatrixDataOut;
                                    nRead <= 1;
                                end //end 11
                                
                                12:begin
                                    // Output data to proper destination.
                                    ExeDataOut <= Result;
                                    nWrite <= 0;
                                    address = 16'h 0000+destAddress;
                                    // Save to an internal register
                                    if(address[15:12] == 4'h 1) InternalReg[address[11:0]] = Result;
                                end //end 12
                                
                                // Proceed to next state
                                13:begin
                                    nWrite <= 1;
                                    currentState <= Clear;
                                end //end 13
                                
                                // Default to clear condition
                                default:begin
                                    if(clkCount > 14) currentState <= Clear;
                                end //end default

                            endcase //end case: clkCount
                        // Advance clock count
                        if(clkCount != 0) clkCount++; 
                        
                        end // End MMult1
                        
                        MMult2:begin
                            case(clkCount)
                                1:begin
                                    //Read in source 1 from Memory
                                    nRead <= 0;
                                    address <= 16'h 0000 + srcAddress1;
                                end //end 1
                                
                                2:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData1 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData1 <= InternalReg[address[11:0]];
                                    // For source data 2
                                    address <= 16'h 0000 + srcAddress2;
                                end //end 2
                                
                                3:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData2 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData2 <= InternalReg[address[11:0]];
                                    //end Read
                                    nRead <= 1;
                                end //end 3
                                
                                4:begin
                                    // Write data to Matrix ALU
                                    // Source 1:
                                    address <= 16'h 3002;
                                    ExeDataOut <= srcData1;
                                    nWrite <= 0;
                                end //end 4
                                
                                6:begin
                                // Source 2:
                                    address <= 16'h 3003;
                                    ExeDataOut <= srcData2;
                                end //end 6
                                
                                7:begin
                                    // End Write
                                    nWrite <= 1;
                                    // Signal Status In: Matrix will perform MMult2
                                    address <= 16'h 3000;
                                    ExeDataOut <= MMult2;
                                end //end 7
                                
                                8:begin
                                    nRead <= 0;
                                    address <= 16'h 3001;
                                end //end 8
                                
                                9:begin
                                    // Obtain result
                                    // Wait for Status out by Matrix ALU
                                    if(MatrixDataOut != 1) wait(MatrixDataOut == 1);
                                    else address <= 16'h 3004;
                                end //end 9
                                
                                11:begin
                                    // Set result
                                    Result <= MatrixDataOut;
                                    nRead <= 1;
                                end //end 11
                                
                                12:begin
                                    // Output data to proper destination.
                                    ExeDataOut <= Result;
                                    nWrite <= 0;
                                    address = 16'h 0000+destAddress;
                                    // Save to an internal register
                                    if(address[15:12] == 4'h 1) InternalReg[address[11:0]] = Result;
                                end //end 12
                                
                                // Proceed to next state
                                13:begin
                                    nWrite <= 1;
                                    currentState <= Clear;
                                end //end 13
                                
                                // Default to clear condition
                                default:begin
                                    if(clkCount > 14) currentState <= Clear;
                                end //end default

                            endcase //end case: clkCount
                        // Advance clock count
                        if(clkCount != 0) clkCount++; 
                        
                        end // End MMult2
                        
                        MMult3:begin
                            case(clkCount)
                                1:begin
                                    //Read in source 1 from Memory
                                    nRead <= 0;
                                    address <= 16'h 0000 + srcAddress1;
                                end //end 1
                                
                                2:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData1 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData1 <= InternalReg[address[11:0]];
                                    // For source data 2
                                    address <= 16'h 0000 + srcAddress2;
                                end //end 2
                                
                                3:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData2 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData2 <= InternalReg[address[11:0]];
                                    //end Read
                                    nRead <= 1;
                                end //end 3
                                
                                4:begin
                                    // Write data to Matrix ALU
                                    // Source 1:
                                    address <= 16'h 3002;
                                    ExeDataOut <= srcData1;
                                    nWrite <= 0;
                                end //end 4
                                
                                6:begin
                                // Source 2:
                                    address <= 16'h 3003;
                                    ExeDataOut <= srcData2;
                                end //end 6
                                
                                7:begin
                                    // End Write
                                    nWrite <= 1;
                                    // Signal Status In: Matrix will perform MMult3
                                    address <= 16'h 3000;
                                    ExeDataOut <= MMult3;
                                end //end 7
                                
                                8:begin
                                    nRead <= 0;
                                    address <= 16'h 3001;
                                end //end 8
                                
                                9:begin
                                    // Obtain result
                                    // Wait for Status out by Matrix ALU
                                    if(MatrixDataOut != 1) wait(MatrixDataOut == 1);
                                    else address <= 16'h 3004;
                                end //end 9
                                
                                11:begin
                                    // Set result
                                    Result <= MatrixDataOut;
                                    nRead <= 1;
                                end //end 11
                                
                                12:begin
                                    // Output data to proper destination.
                                    ExeDataOut <= Result;
                                    nWrite <= 0;
                                    address = 16'h 0000+destAddress;
                                    // Save to an internal register
                                    if(address[15:12] == 4'h 1) InternalReg[address[11:0]] = Result;
                                end //end 12
                                
                                // Proceed to next state
                                13:begin
                                    nWrite <= 1;
                                    currentState <= Clear;
                                end //end 13
                                
                                // Default to clear condition
                                default:begin
                                    if(clkCount > 14) currentState <= Clear;
                                end //end default

                            endcase //end case: clkCount
                        // Advance clock count
                        if(clkCount != 0) clkCount++; 
                        
                        end // End MMult3
                        
                        Madd:begin
                            case(clkCount)
                                1:begin
                                    //Read in source 1 from Memory
                                    nRead <= 0;
                                    address <= 16'h 0000 + srcAddress1;
                                end //end 1
                                
                                2:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData1 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData1 <= InternalReg[address[11:0]];
                                    // For source data 2
                                    address <= 16'h 0000 + srcAddress2;
                                end //end 2
                                
                                3:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData2 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData2 <= InternalReg[address[11:0]];
                                    //end Read
                                    nRead <= 1;
                                end //end 3
                                
                                4:begin
                                    // Write data to Matrix ALU
                                    // Source 1:
                                    address <= 16'h 3002;
                                    ExeDataOut <= srcData1;
                                    nWrite <= 0;
                                end //end 4
                                
                                6:begin
                                // Source 2:
                                    address <= 16'h 3003;
                                    ExeDataOut <= srcData2;
                                end //end 6
                                
                                7:begin
                                    // End Write
                                    nWrite <= 1;
                                    // Signal Status In: Matrix will perform Madd
                                    address <= 16'h 3000;
                                    ExeDataOut <= Madd;
                                end //end 7
                                
                                8:begin
                                    nRead <= 0;
                                    address <= 16'h 3001;
                                end //end 8
                                
                                9:begin
                                    // Obtain result
                                    // Wait for Status out by Matrix ALU
                                    if(MatrixDataOut != 1) wait(MatrixDataOut == 1);
                                    else address <= 16'h 3004;
                                end //end 9
                                
                                11:begin
                                    // Set result
                                    Result <= MatrixDataOut;
                                    nRead <= 1;
                                end //end 11
                                
                                12:begin
                                    // Output data to proper destination.
                                    ExeDataOut <= Result;
                                    nWrite <= 0;
                                    address = 16'h 0000+destAddress;
                                    // Save to an internal register
                                    if(address[15:12] == 4'h 1) InternalReg[address[11:0]] = Result;
                                end //end 12
                                
                                // Proceed to next state
                                13:begin
                                    nWrite <= 1;
                                    currentState <= Clear;
                                end //end 13
                                
                                // Default to clear condition
                                default:begin
                                    if(clkCount > 14) currentState <= Clear;
                                end //end default

                            endcase //end case: clkCount
                        // Advance clock count
                        if(clkCount != 0) clkCount++; 
                        
                        end // End Madd
                        
                        Msub:begin
                            case(clkCount)
                                1:begin
                                    //Read in source 1 from Memory
                                    nRead <= 0;
                                    address <= 16'h 0000 + srcAddress1;
                                end //end 1
                                
                                2:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData1 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData1 <= InternalReg[address[11:0]];
                                    // For source data 2
                                    address <= 16'h 0000 + srcAddress2;
                                end //end 2
                                
                                3:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData2 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData2 <= InternalReg[address[11:0]];
                                    //end Read
                                    nRead <= 1;
                                end //end 3
                                
                                4:begin
                                    // Write data to Matrix ALU
                                    // Source 1:
                                    address <= 16'h 3002;
                                    ExeDataOut <= srcData1;
                                    nWrite <= 0;
                                end //end 4
                                
                                6:begin
                                // Source 2:
                                    address <= 16'h 3003;
                                    ExeDataOut <= srcData2;
                                end //end 6
                                
                                7:begin
                                    // End Write
                                    nWrite <= 1;
                                    // Signal Status In: Matrix will perform Msub
                                    address <= 16'h 3000;
                                    ExeDataOut <= Msub;
                                end //end 7
                                
                                8:begin
                                    nRead <= 0;
                                    address <= 16'h 3001;
                                end //end 8
                                
                                9:begin
                                    // Obtain result
                                    // Wait for Status out by Matrix ALU
                                    if(MatrixDataOut != 1) wait(MatrixDataOut == 1);
                                    else address <= 16'h 3004;
                                end //end 9
                                
                                11:begin
                                    // Set result
                                    Result <= MatrixDataOut;
                                    nRead <= 1;
                                end //end 11
                                
                                12:begin
                                    // Output data to proper destination.
                                    ExeDataOut <= Result;
                                    nWrite <= 0;
                                    address = 16'h 0000+destAddress;
                                    // Save to an internal register
                                    if(address[15:12] == 4'h 1) InternalReg[address[11:0]] = Result;
                                end //end 12
                                
                                // Proceed to next state
                                13:begin
                                    nWrite <= 1;
                                    currentState <= Clear;
                                end //end 13
                                
                                // Default to clear condition
                                default:begin
                                    if(clkCount > 14) currentState <= Clear;
                                end //end default

                            endcase //end case: clkCount
                        // Advance clock count
                        if(clkCount != 0) clkCount++; 
                        
                        end // End Msub
                        
                        Mtranspose:begin
                            case(clkCount)
                                1:begin
                                    //Read in source 1 from Memory
                                    nRead <= 0;
                                    address <= 16'h 0000 + srcAddress1;
                                end //end 1
                                
                                2:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData1 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData1 <= InternalReg[address[11:0]];
                                    // For source data 2
                                    address <= 16'h 0000 + srcAddress2;
                                end //end 2
                                
                                3:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData2 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData2 <= InternalReg[address[11:0]];
                                    //end Read
                                    nRead <= 1;
                                end //end 3
                                
                                4:begin
                                    // Write data to Matrix ALU
                                    // Source 1:
                                    address <= 16'h 3002;
                                    ExeDataOut <= srcData1;
                                    nWrite <= 0;
                                end //end 4
                                
                                6:begin
                                // Source 2:
                                    address <= 16'h 3003;
                                    ExeDataOut <= srcData2;
                                end //end 6
                                
                                7:begin
                                    // End Write
                                    nWrite <= 1;
                                    // Signal Status In: Matrix will perform Mtranspose
                                    address <= 16'h 3000;
                                    ExeDataOut <= Mtranspose;
                                end //end 7
                                
                                8:begin
                                    nRead <= 0;
                                    address <= 16'h 3001;
                                end //end 8
                                
                                9:begin
                                    // Obtain result
                                    // Wait for Status out by Matrix ALU
                                    if(MatrixDataOut != 1) wait(MatrixDataOut == 1);
                                    else address <= 16'h 3004;
                                end //end 9
                                
                                11:begin
                                    // Set result
                                    Result <= MatrixDataOut;
                                    nRead <= 1;
                                end //end 11
                                
                                12:begin
                                    // Output data to proper destination.
                                    ExeDataOut <= Result;
                                    nWrite <= 0;
                                    address = 16'h 0000+destAddress;
                                    // Save to an internal register
                                    if(address[15:12] == 4'h 1) InternalReg[address[11:0]] = Result;
                                end //end 12
                                
                                // Proceed to next state
                                13:begin
                                    nWrite <= 1;
                                    currentState <= Clear;
                                end //end 13
                                
                                // Default to clear condition
                                default:begin
                                    if(clkCount > 14) currentState <= Clear;
                                end //end default

                            endcase //end case: clkCount
                        // Advance clock count
                        if(clkCount != 0) clkCount++; 
                        
                        end // End Mtranspose
                        
                        MScale:begin
                            case(clkCount)
                                1:begin
                                    //Read in source 1 from Memory
                                    nRead <= 0;
                                    address <= 16'h 0000 + srcAddress1;
                                end //end 1
                                
                                2:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData1 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData1 <= InternalReg[address[11:0]];
                                    // For source data 2
                                    address <= 16'h 0000 + srcAddress2;
                                end //end 2
                                
                                3:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData2 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData2 <= InternalReg[address[11:0]];
                                    //end Read
                                    nRead <= 1;
                                end //end 3
                                
                                4:begin
                                    // Write data to Matrix ALU
                                    // Source 1:
                                    address <= 16'h 3002;
                                    ExeDataOut <= srcData1;
                                    nWrite <= 0;
                                end //end 4
                                
                                6:begin
                                // Source 2:
                                    address <= 16'h 3003;
                                    ExeDataOut <= srcData2;
                                end //end 6
                                
                                7:begin
                                    // End Write
                                    nWrite <= 1;
                                    // Signal Status In: Matrix will perform MScale
                                    address <= 16'h 3000;
                                    ExeDataOut <= MScale;
                                end //end 7
                                
                                8:begin
                                    nRead <= 0;
                                    address <= 16'h 3001;
                                end //end 8
                                
                                9:begin
                                    // Obtain result
                                    // Wait for Status out by Matrix ALU
                                    if(MatrixDataOut != 1) wait(MatrixDataOut == 1);
                                    else address <= 16'h 3004;
                                end //end 9
                                
                                11:begin
                                    // Set result
                                    Result <= MatrixDataOut;
                                    nRead <= 1;
                                end //end 11
                                
                                12:begin
                                    // Output data to proper destination.
                                    ExeDataOut <= Result;
                                    nWrite <= 0;
                                    address = 16'h 0000+destAddress;
                                    // Save to an internal register
                                    if(address[15:12] == 4'h 1) InternalReg[address[11:0]] = Result;
                                end //end 12
                                
                                // Proceed to next state
                                13:begin
                                    nWrite <= 1;
                                    currentState <= Clear;
                                end //end 13
                                
                                // Default to clear condition
                                default:begin
                                    if(clkCount > 14) currentState <= Clear;
                                end //end default

                            endcase //end case: clkCount
                        // Advance clock count
                        if(clkCount != 0) clkCount++; 
                        
                        end // End MScale
                        
                        MScaleImm:begin
                            case(clkCount)
                                1:begin
                                    //Read in source 1 from Memory
                                    nRead <= 0;
                                    address <= 16'h 0000 + srcAddress1;
                                end //end 1
                                
                                2:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData1 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData1 <= InternalReg[address[11:0]];
                                    // For source data 2
                                    address <= 16'h 0000 + srcAddress2;
                                end //end 2
                                
                                3:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData2 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData2 <= InternalReg[address[11:0]];
                                    //end Read
                                    nRead <= 1;
                                end //end 3
                                
                                4:begin
                                    // Write data to Matrix ALU
                                    // Source 1:
                                    address <= 16'h 3002;
                                    ExeDataOut <= srcData1;
                                    nWrite <= 0;
                                end //end 4
                                
                                6:begin
                                // Source 2:
                                    address <= 16'h 3003;
                                    ExeDataOut <= srcData2;
                                end //end 6
                                
                                7:begin
                                    // End Write
                                    nWrite <= 1;
                                    // Signal Status In: Matrix will perform MScaleImm
                                    address <= 16'h 3000;
                                    ExeDataOut <= MScaleImm;
                                end //end 7
                                
                                8:begin
                                    nRead <= 0;
                                    address <= 16'h 3001;
                                end //end 8
                                
                                9:begin
                                    // Obtain result
                                    // Wait for Status out by Matrix ALU
                                    if(MatrixDataOut != 1) wait(MatrixDataOut == 1);
                                    else address <= 16'h 3004;
                                end //end 9
                                
                                11:begin
                                    // Set result
                                    Result <= MatrixDataOut;
                                    nRead <= 1;
                                end //end 11
                                
                                12:begin
                                    // Output data to proper destination.
                                    ExeDataOut <= Result;
                                    nWrite <= 0;
                                    address = 16'h 0000+destAddress;
                                    // Save to an internal register
                                    if(address[15:12] == 4'h 1) InternalReg[address[11:0]] = Result;
                                end //end 12
                                
                                // Proceed to next state
                                13:begin
                                    nWrite <= 1;
                                    currentState <= Clear;
                                end //end 13
                                
                                // Default to clear condition
                                default:begin
                                    if(clkCount > 14) currentState <= Clear;
                                end //end default

                            endcase //end case: clkCount
                        // Advance clock count
                        if(clkCount != 0) clkCount++; 
                        
                        end // End MScaleImm
                        
                        IntAdd:begin
                            case(clkCount)
                                1:begin
                                    //Read in source 1 from Memory
                                    nRead <= 0;
                                    address <= 16'h 0000 + srcAddress1;
                                end //end 1
                                
                                2:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData1 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData1 <= InternalReg[address[11:0]];
                                    // For source data 2
                                    address <= 16'h 0000 + srcAddress2;
                                end //end 2
                                
                                3:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData2 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData2 <= InternalReg[address[11:0]];
                                    //end Read
                                    nRead <= 1;
                                end //end 3
                                
                                4:begin
                                    // Write data to Integer ALU 
                                    // Source 1:
                                    address <= 16'h 5002;
                                    ExeDataOut <= srcData1;
                                    nWrite <= 0;
                                end //end 4
                                
                                6:begin
                                // Source 2:
                                    address <= 16'h 5003;
                                    ExeDataOut <= srcData2;
                                end //end 6
                                
                                7:begin
                                    // End Write
                                    nWrite <= 1;
                                    // Signal Status In: Integer ALU will perform IntAdd
                                    address <= 16'h 5000;
                                    ExeDataOut <= IntAdd;
                                end //end 7
                                
                                8:begin
                                    nRead <= 0;
                                    address <= 16'h 5001;
                                end //end 8
                                
                                9:begin
                                    // Obtain result
                                    // Wait for Status out by Integer ALU
                                    if(IntDataOut != 1) wait(IntDataOut == 1);
                                    else address <= 16'h 5004;
                                end //end 8
                                
                                11:begin
                                    // Set result
                                    Result <= IntDataOut;
                                    nRead <= 1;
                                end //end 9
                                
                                12:begin
                                    // Output data to proper destination.
                                    ExeDataOut <= Result;
                                    nWrite <= 0;
                                    address = 16'h 0000+destAddress;
                                    // Save to an internal register
                                    if(address[15:12] == 4'h 1) InternalReg[address[11:0]] = Result;
                                end //end 12
                                
                                13:begin
                                    // Proceed to next state
                                    nWrite <= 1;
                                    currentState <= Clear;
                                end //end 13
                                // Default to clear condition
                                default:begin
                                    if(clkCount > 14) currentState <= Clear;
                                end //end default
                                
                            endcase //end case: clkCount
                            
                        // Advance clock count
                        if(clkCount != 0) clkCount++; 
                        end // End IntAdd
                        
                        IntSub:begin
                            case(clkCount)
                                1:begin
                                    //Read in source 1 from Memory
                                    nRead <= 0;
                                    address <= 16'h 0000 + srcAddress1;
                                end //end 1
                                
                                2:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData1 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData1 <= InternalReg[address[11:0]];
                                    // For source data 2
                                    address <= 16'h 0000 + srcAddress2;
                                end //end 2
                                
                                3:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData2 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData2 <= InternalReg[address[11:0]];
                                    //end Read
                                    nRead <= 1;
                                end //end 3
                                
                                4:begin
                                    // Write data to Integer ALU 
                                    // Source 1:
                                    address <= 16'h 5002;
                                    ExeDataOut <= srcData1;
                                    nWrite <= 0;
                                end //end 4
                                
                                6:begin
                                // Source 2:
                                    address <= 16'h 5003;
                                    ExeDataOut <= srcData2;
                                end //end 6
                                
                                7:begin
                                    // End Write
                                    nWrite <= 1;
                                    // Signal Status In: Integer ALU will perform IntSub
                                    address <= 16'h 5000;
                                    ExeDataOut <= IntSub;
                                end //end 7
                                
                                8:begin
                                    nRead <= 0;
                                    address <= 16'h 5001;
                                end //end 8
                                
                                9:begin
                                    // Obtain result
                                    // Wait for Status out by Integer ALU
                                    if(IntDataOut != 1) wait(IntDataOut == 1);
                                    else address <= 16'h 5004;
                                end //end 8
                                
                                11:begin
                                    // Set result
                                    Result <= IntDataOut;
                                    nRead <= 1;
                                end //end 9
                                
                                12:begin
                                    // Output data to proper destination.
                                    ExeDataOut <= Result;
                                    nWrite <= 0;
                                    address = 16'h 0000+destAddress;
                                    // Save to an internal register
                                    if(address[15:12] == 4'h 1) InternalReg[address[11:0]] = Result;
                                end //end 12
                                
                                13:begin
                                    // Proceed to next state
                                    nWrite <= 1;
                                    currentState <= Clear;
                                end //end 13
                                // Default to clear condition
                                default:begin
                                    if(clkCount > 14) currentState <= Clear;
                                end //end default
                                
                            endcase //end case: clkCount
                            
                        // Advance clock count
                        if(clkCount != 0) clkCount++; 
                        end //End IntSub
                        
                        IntMult:begin
                            case(clkCount)
                                1:begin
                                    //Read in source 1 from Memory
                                    nRead <= 0;
                                    address <= 16'h 0000 + srcAddress1;
                                end //end 1
                                
                                2:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData1 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData1 <= InternalReg[address[11:0]];
                                    // For source data 2
                                    address <= 16'h 0000 + srcAddress2;
                                end //end 2
                                
                                3:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData2 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData2 <= InternalReg[address[11:0]];
                                    //end Read
                                    nRead <= 1;
                                end //end 3
                                
                                4:begin
                                    // Write data to Integer ALU 
                                    // Source 1:
                                    address <= 16'h 5002;
                                    ExeDataOut <= srcData1;
                                    nWrite <= 0;
                                end //end 4
                                
                                6:begin
                                // Source 2:
                                    address <= 16'h 5003;
                                    ExeDataOut <= srcData2;
                                end //end 6
                                
                                7:begin
                                    // End Write
                                    nWrite <= 1;
                                    // Signal Status In: Integer ALU will perform IntMult
                                    address <= 16'h 5000;
                                    ExeDataOut <= IntMult;
                                end //end 7
                                
                                8:begin
                                    nRead <= 0;
                                    address <= 16'h 5001;
                                end //end 8
                                
                                9:begin
                                    // Obtain result
                                    // Wait for Status out by Integer ALU
                                    if(IntDataOut != 1) wait(IntDataOut == 1);
                                    else address <= 16'h 5004;
                                end //end 8
                                
                                11:begin
                                    // Set result
                                    Result <= IntDataOut;
                                    nRead <= 1;
                                end //end 9
                                
                                12:begin
                                    // Output data to proper destination.
                                    ExeDataOut <= Result;
                                    nWrite <= 0;
                                    address = 16'h 0000+destAddress;
                                    // Save to an internal register
                                    if(address[15:12] == 4'h 1) InternalReg[address[11:0]] = Result;
                                end //end 12
                                
                                13:begin
                                    // Proceed to next state
                                    nWrite <= 1;
                                    currentState <= Clear;
                                end //end 13
                                // Default to clear condition
                                default:begin
                                    if(clkCount > 14) currentState <= Clear;
                                end //end default
                                
                            endcase //end case: clkCount
                            
                        // Advance clock count
                        if(clkCount != 0) clkCount++; 
                        end // End IntMult
                        
                        IntDiv:begin
                            case(clkCount)
                                1:begin
                                    //Read in source 1 from Memory
                                    nRead <= 0;
                                    address <= 16'h 0000 + srcAddress1;
                                end //end 1
                                
                                2:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData1 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData1 <= InternalReg[address[11:0]];
                                    // For source data 2
                                    address <= 16'h 0000 + srcAddress2;
                                end //end 2
                                
                                3:begin
                                    // Check if in Memory/Register
                                    if(address[15:12] == 4'h 0)srcData2 <= MemDataOut;
                                    if(address[15:12] == 4'h 1)srcData2 <= InternalReg[address[11:0]];
                                    //end Read
                                    nRead <= 1;
                                end //end 3
                                
                                4:begin
                                    // Write data to Integer ALU 
                                    // Source 1:
                                    address <= 16'h 5002;
                                    ExeDataOut <= srcData1;
                                    nWrite <= 0;
                                end //end 4
                                
                                6:begin
                                // Source 2:
                                    address <= 16'h 5003;
                                    ExeDataOut <= srcData2;
                                end //end 6
                                
                                7:begin
                                    // End Write
                                    nWrite <= 1;
                                    // Signal Status In: Integer ALU will perform IntDiv
                                    address <= 16'h 5000;
                                    ExeDataOut <= IntDiv;
                                end //end 7
                                
                                8:begin
                                    nRead <= 0;
                                    address <= 16'h 5001;
                                end //end 8
                                
                                9:begin
                                    // Obtain result
                                    // Wait for Status out by Integer ALU
                                    if(IntDataOut != 1) wait(IntDataOut == 1);
                                    else address <= 16'h 5004;
                                end //end 8
                                
                                11:begin
                                    // Set result
                                    Result <= IntDataOut;
                                    nRead <= 1;
                                end //end 9
                                
                                12:begin
                                    // Output data to proper destination.
                                    ExeDataOut <= Result;
                                    nWrite <= 0;
                                    address = 16'h 0000+destAddress;
                                    // Save to an internal register
                                    if(address[15:12] == 4'h 1) InternalReg[address[11:0]] = Result;
                                end //end 12
                                
                                13:begin
                                    // Proceed to next state
                                    nWrite <= 1;
                                    currentState <= Clear;
                                end //end 13
                                // Default to clear condition
                                default:begin
                                    if(clkCount > 14) currentState <= Clear;
                                end //end default
                                
                            endcase //end case: clkCount
                            
                        // Advance clock count
                        if(clkCount != 0) clkCount++; 
                        end // End IntDiv




                    endcase //End case: operation
                    
                end // End Execute
                
                // Internal Reset Condition
                Clear:begin
                    PC++;
                    nWrite <= 1;
                    nRead <= 1;
                    ExeDataOut <= 256'h x;
                    clkCount <= 0;    
                end // End Clear

            endcase // end Case: currentState
            
        end // End If nReset high && not done
    
    end //End Always_ff posedge Clk

endmodule