// Mark W. welker
// Instruction memory. 
// holds the instructions that the processor will execute.
//
// the address lines are generic and each module must handle thier own decode. 
// The address bus is large enough that each module can contain a local address decode. This will save on multiple enmables. 
// bit 11-0 are for adressing inside each unit.
// nWrite = 0 means databus is being written into the part on the falling edge of write
// nRead = 0 means it is expected to drive the databus while this signal is low and the address is correct until the nRead goes high independent of addressd bus.


parameter MainMemEn = 0;            // Main Memory
parameter RegisterEn = 1;           // Internal Register in Execution
parameter InstrMemEn = 2;           // Instruction Memory
parameter AluEn = 3;                // Matrix ALU
parameter ExecuteEn = 4;            // Probably won't ever use this...
parameter IntAlu = 5;               // Integer ALU

// Alu Register setup // same register sequence for both ALU's 
parameter AluStatusIn = 0;
parameter AluStatusOut = 1;
parameter ALU_Source1 = 2;
parameter ALU_Source2 = 3;
parameter  ALU_Result = 4;
parameter Overflow_err = 5;

//////////////////////////////
//Moved stop to third instruction for this example
/////////////////////////////////////////////////
// instruction: OPcode :: dest :: src1 :: src2 Each section is 8 bits.
//Stop::FFh::00::00::00
//MMult1::00h::Reg/mem::Reg/mem::Reg/mem
//MMult2::01h::Reg/mem::Reg/mem::Reg/mem
//MMult3::02h::Reg/mem::Reg/mem::Reg/mem
//Madd::03h::Reg/mem::Reg/mem::Reg/mem
//Msub::04h::Reg/mem::Reg/mem::Reg/mem
//Mtranspose::05h::Reg/mem::Reg/mem::Reg/mem
//MScale::06h::Reg/mem::Reg/mem::Reg/mem
//MScaleImm::07h:Reg/mem::Reg/mem::Immediate
//IntAdd::10h::Reg/mem::Reg/mem::Reg/mem
//IntSub::11h::Reg/mem::Reg/mem::Reg/mem
//IntMult::12h::Reg/mem::Reg/mem::Reg/mem
//IntDiv::13h::Reg/mem::Reg/mem::Reg/mem

// add the data at location 0 to the data at location 1 and place result in location 2
parameter Instruct1 = 32'h 03_02_00_01; // add first matrix to second matrix store in memory
parameter Instruct2 = 32'h 10_10_0a_0b; // add 16 bit numbers in location a to b store in temp register
parameter Instruct3 = 32'h 04_03_02_00; //Subtract the first matrix from the result in step 1 and store the result somewhere else in memory. 
parameter Instruct4 = 32'h 05_04_02_00;//Transpose the result from step 1 store in memory
parameter Instruct5 = 32'h 07_11_03_10;//ScaleImm the result in step 3 by the result from step 2 store in a matrix register
parameter Instruct6 = 32'h 00_05_04_03; //Multiply the result from step 4 by the result in step 3, store in memory. 4x4 * 4x4
parameter Instruct7 = 32'h 01_06_04_03; //Multiply the result from step 6 by the result in step 5, store in memory. 4x2 * 2x4
parameter Instruct8 = 32'h 02_07_04_03; //Multiply the result from step 5 by the result in step 4, store in memory. 2x4 * 4x2

parameter Instruct9 = 32'h 12_0a_01_00;//Multiply the integer value in memory location 0 to location 1. Store it in memory location 0x0A
parameter Instruct10 = 32'h 11_12_0a_01;//Subtract the integer value in memory location 01 from memory location 0x0A and store it in a register
parameter Instruct11 = 32'h 13_0b_0a_12;//Divide Memory location 0x0A by the register in step 8 and store it in location 0x0B
parameter Instruct12 = 32'h FF_00_00_00; // stop


module InstructionMemory(Clk,Dataout, address, nRead,nReset);
// NOTE the lack of datain and write. This is because this is a ROM model

input logic nRead, nReset, Clk;
input logic [15:0] address;

output logic [31:0] Dataout; // 1 - 32 it instructions at a time.

  logic [31:0]InstructMemory[12]; // this is the physical memory

// This memory is designed to be driven into a data multiplexor. 

  always_ff @(negedge Clk or negedge nReset)
begin
  if (!nReset)
    Dataout = 0;
  else begin
  if(address[15:12] == InstrMemEn) // talking to Instruction IntstrMemEn
		begin
			if(~nRead)begin
				Dataout <= InstructMemory[address[11:0]]; // data will reamin on dataout until it is changed.
			end
		end
	end
end // from negedge nRead	

always @(negedge nReset)
begin
//	set in the default instructions 
//
	InstructMemory[0] = Instruct1;  	
	InstructMemory[1] = Instruct2;  	
  	InstructMemory[2] = Instruct3;
	InstructMemory[3] = Instruct4;	
	InstructMemory[4] = Instruct5;
	InstructMemory[5] = Instruct6;
	InstructMemory[6] = Instruct7;
	InstructMemory[7] = Instruct8;
	InstructMemory[8] = Instruct9;
	InstructMemory[9] = Instruct10;
	InstructMemory[10] = Instruct11;
	InstructMemory[11] = Instruct12;
	

	
end 

endmodule


