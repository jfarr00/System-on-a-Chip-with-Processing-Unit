
// Mark W. Welker
// HDL 4321 Spring 2023
// Matrix addition assignment top module
//
// Main memory MUST be allocated in the mainmemory module as per teh next line.
//  logic [255:0]MainMemory[12]; // this is the physical memory
//



module top ();

logic [255:0] InstructDataOut;
logic [255:0] MemDataOut;
logic [255:0] ExeDataOut;
logic [255:0] IntDataOut;
logic [255:0] MatrixDataOut;
logic nRead,nWrite,nReset,Clk;
logic [15:0] address;

logic Fail;

InstructionMemory  U1(Clk,InstructDataOut, address, nRead,nReset);

MainMemory  U2(Clk,MemDataOut,ExeDataOut, address, nRead,nWrite, nReset);

Execution  U3(Clk,InstructDataOut,MemDataOut,MatrixDataOut,IntDataOut,ExeDataOut, address, nRead,nWrite, nReset);

MatrixAlu  U4(Clk,MatrixDataOut,ExeDataOut, address, nRead,nWrite, nReset);

IntegerAlu  U5(Clk,IntDataOut,ExeDataOut, address, nRead,nWrite, nReset);

TestMatrix  UTest(Clk,nReset);

  initial begin //. setup to allow waveforms for edaplayground
   $dumpfile("dump.vcd");
   $dumpvars(1);
    Fail = 0; // SETUP TO PASS TO START 
 end

always @(InstructDataOut) begin // this block checks to make certain the proper data is in the memory.
		if (InstructDataOut[31:0] == 32'hff000000)
// we are about to execute the stop
begin 
// Print out the entire contents of main memory so I can copy and paste.
			$display ( "memory location 0 = %h", U2.MainMemory[0]);
			$display ( "memory location 1 = %h", U2.MainMemory[1]);
			$display ( "memory location 2 = %h", U2.MainMemory[2]);
			$display ( "memory location 3 = %h", U2.MainMemory[3]);
			$display ( "memory location 4 = %h", U2.MainMemory[4]);
			$display ( "memory location 5 = %h", U2.MainMemory[5]);
			$display ( "memory location 6 = %h", U2.MainMemory[6]);
			$display ( "memory location 7 = %h", U2.MainMemory[7]);
			$display ( "memory location 8 = %h", U2.MainMemory[8]);
			$display ( "memory location 9 = %h", U2.MainMemory[9]);
			$display ( "memory location 10 = %h", U2.MainMemory[10]);
			$display ( "memory location 11 = %h", U2.MainMemory[11]);
			$display ( "memory location 12 = %h", U2.MainMemory[12]);
			$display ( "memory location 13 = %h", U2.MainMemory[13]);

			$display ( "Imternal Reg location 0 = %h", U3.InternalReg[0]);
			$display ( "Internal reg location 1 = %h", U3.InternalReg[1]);
			$display ( "Internal reg location 2 = %h", U3.InternalReg[2]);
			$display ( "Internal reg location 3 = %h", U3.InternalReg[3]);
			
		if (U2.MainMemory[0] == 256'h0008000c00080006000c0010000d0009000a00090005000d000c0003000a0006)
			$display ( "memory location 0 is Correct");
		else begin Fail = 1; $display ( "memory location 0 is Wrong"); end
		if (U2.MainMemory[1] == 256'h000300040007000800070008000e000700100009000c000b000c000500050006)
			$display ( "memory location 1 is Correct");
		else begin Fail = 1;$display ( "memory location 1 is Wrong"); end
		if (U2.MainMemory[2] == 256'h000b0010000f000e00130018001b0010001a00120011001800180008000f000c)
			$display ( "memory location 2 is Correct");
		else begin Fail = 1;$display ( "memory location 2 is Wrong"); end
		if (U2.MainMemory[3] == 256'h000300040007000800070008000e000700100009000c000b000c000500050006)
			$display ( "memory location 3 is Correct");
		else begin Fail = 1;$display ( "memory location 3 is Wrong"); end
		if (U2.MainMemory[4] == 256'h000b0013001a00180010001800120008000f001b0011000f000e00100018000c)
			$display ( "memory location 4 is Correct");
		else begin Fail = 1;$display ( "memory location 4 is Wrong"); end
		if (U2.MainMemory[5] == 256'h036602260307028b025801ca02c0021e02ae01f802fa024a02aa01cc029e0230)
			$display ( "memory location 5 is Correct");
		else begin Fail = 1;$display ( "memory location 5 is Wrong"); end
		if (U2.MainMemory[6] == 256'h02c0016201b001ae018000ca010000f601c400e40117011502100114015c0150)
			$display ( "memory location 6 is Correct");
		else begin Fail = 1;$display ( "memory location 6 is Wrong"); end
		if (U2.MainMemory[7] == 256'h00000000000000000000000000000000000000000000000002fa024a029e0230)
			$display ( "memory location 7 is Correct");
		else begin Fail = 1;$display ( "memory location 7 is Wrong"); end
		if (U2.MainMemory[8] == 256'h0000000000000000000000000000000000000000000000000000000000000000)
			$display ( "memory location 8 is Correct");
		else begin Fail = 1;$display ( "memory location 8 is Wrong"); end
		if (U2.MainMemory[9] == 256'h0000000000000000000000000000000000000000000000000000000000000000)
			$display ( "memory location 9 is Correct");
		else begin Fail = 1;$display ( "memory location 9 is Wrong"); end
		if (U2.MainMemory[10][15:0] == 16'h0024)
			$display ( "memory location 10 is Correct");
		else begin Fail = 1;$display ( "memory location 10 is Wrong"); end
		if (U2.MainMemory[11][15:0] == 16'h0000)
			$display ( "memory location 11 is Correct");
		else begin Fail = 1;$display ( "memory location 11 is Wrong"); end


		if (U3.InternalReg[0][15:0] == 16'h0013)
			$display ( "Interal reg location 0 is Correct");
		else begin Fail = 1; $display ( "Internal Register 0 is Wrong"); end
		if (U3.InternalReg[1] == 256'h0039004c0085009800850098010a0085013000ab00e400d100e4005f005f0072)
			$display ( "Internal Reg location 1 is Correct");
		else begin Fail = 1; $display ( "Internal Register 1 is Wrong"); end
		if (U3.InternalReg[2][15:0] == 16'h001e)
			$display ( "Internal Reg location 2 is Correct");
		else begin Fail = 1; $display ( "Internal Register 2 is Wrong"); end

        if (Fail) begin
        $display("********************************************");
        $display(" Project did not return the proper values");
        $display("********************************************");
        end
        else begin
        $display("********************************************");
        $display(" Project PASSED memory check");
        $display("********************************************");
        end
        
        end

end


endmodule
