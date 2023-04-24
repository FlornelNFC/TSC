/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/

module instr_register_test
  import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
  (input  logic          clk,
   output logic          load_en,
   output logic          reset_n,
   output operand_t      operand_a,
   output operand_t      operand_b,
   output opcode_t       opcode,
   output address_t      write_pointer,
   output address_t      read_pointer,
   input  instruction_t  instruction_word
   //output reg [3:0] rand_out
  );

  timeunit 1ns/1ns;
  //reg [3:0] my_list [2:0] = '{4'b0101, 4'b0111, 4'b1011};
  //int index = $unsigned($urandom())%3;
  //parameter Number_of_Transaction = my_list[index];
  //parameter Number_of_Transaction = 11;

  // generate
  //   if ($urandom() % 3 == 0) begin
  //     parameter Number_of_Transaction = 5;
  //   end else if ($urandom() % 3 == 1) begin
  //     parameter Number_of_Transaction = 7;
  //   end else begin
  //     parameter Number_of_Transaction = 11;
  //   end
  // endgenerate

  parameter Number_of_Transaction;
  parameter RND_CASE;
  parameter testName;
  integer errorCounter = 0;
    /***
  LEGENDA RND_CASE:
  Valoare:
            0: write_pointer -> incremental, read_pointer -> incremental
            1: write_pointer -> incremental, read_pointer -> random
            2: write_pointer -> random, read_pointer -> incremental
            3: write_pointer -> random, read_pointer -> random
  *///
  parameter seed = 555;

  initial begin
    $display("\n\n***********************************************************");
    $display(    "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(    "***********************************************************");

    $display("\nReseting the instruction register...");
    write_pointer  = 5'h00;         // initialize write pointer
    read_pointer   = 5'h1F;         // initialize read pointer
    load_en        = 1'b0;          // initialize load control line
    reset_n       <= 1'b0;          // assert reset_n (active low)
    repeat (2) @(posedge clk) ;     // hold in reset for 2 clock cycles
    reset_n        = 1'b1;          // deassert reset_n (active low)

    $display("\nWriting values to register stack...");
    @(posedge clk) load_en = 1'b1;  // enable writing to register
    repeat (Number_of_Transaction) begin
      @(posedge clk) randomize_transaction;
      @(negedge clk) print_transaction;
    end
    @(posedge clk) load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    for (int i=0; i<Number_of_Transaction; i++) begin
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back
     
    case (RND_CASE)
      0,2: read_pointer = read_pointer + 1; 
      1,3: read_pointer = $unsigned($urandom()) % 32; 
      default: read_pointer = read_pointer + 1; 
    endcase

		@(negedge clk) print_results;
    CheckResults(instruction_word, opcode, operand_a, operand_b);
	
    end

    @(posedge clk) ;
    $display("\n***********************************************************");
    $display(  "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(  "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(  "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(  "***********************************************************\n");
    $display("Nume test: %0s\n", testName);
    $display("Erori: %0d\n", errorCounter);
    if (errorCounter == 0) begin
      $display ("Sequence status: PASSED");
    end else begin
      $display("Sequence status: FAILED");
    end

    
    $finish;
  end

  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //

    case (RND_CASE)
      0, 1: write_pointer = write_pointer + 1;
      2, 3: write_pointer = $unsigned($urandom()) % 32; 
      default: write_pointer = write_pointer + 1; 
    endcase

    operand_a     <= $random(seed)%16;                 // between -15 and 15
    operand_b     <= $unsigned($random)%16;            // between 0 and 15
    opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type


    
  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d",   instruction_word.op_a);
    $display("  operand_b = %0d", instruction_word.op_b);
	  $display("  res = %0d", instruction_word.rez);
  endfunction: print_results

  function void CheckResults (instruction_t Thisinstruction_word, opcode_t Thisopcode, operand_t Thisoperand_a, operand_t Thisoperand_b);
        rezultat_t expectedResult;

        case (Thisinstruction_word.opc)
          ADD: expectedResult = Thisoperand_a + Thisoperand_b;
          SUB: expectedResult = Thisoperand_a - Thisoperand_b;
          MULT: expectedResult = Thisoperand_a * Thisoperand_b;
          PASSA: expectedResult = Thisoperand_a;
          PASSB: expectedResult = Thisoperand_b;
          DIV: expectedResult = Thisoperand_a / Thisoperand_b;
          MOD: expectedResult = Thisoperand_a % Thisoperand_b;
          default: expectedResult = 0;
        endcase

        $display("  Expected Result: %0d", expectedResult);
        $display("  Actual Result: %0d\n", Thisinstruction_word.rez);

        if (expectedResult == Thisinstruction_word.rez) begin
          $display("Current test status: PASSED\n\n");
        end else begin
          $display("Current test status: FAILED\n\n");
          errorCounter++;
        end
  endfunction: CheckResults

  

endmodule: instr_register_test
