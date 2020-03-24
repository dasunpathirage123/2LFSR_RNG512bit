`timescale 1ns / 1ps

module rng512LFSR2 
  #(
    parameter NUM_BITS = 128
   )(

   input aclk,
   input aresetn,
 
   output  reg [NUM_BITS-1:0] pq_fifo_dout,
   output  reg                pq_fifo_wr_en,

   input                      pq_fifo_full,


   output  o_LFSR_Done
   );

    localparam      STATE_INIT    = 0;
    localparam      STATE_1       = 1;
    localparam      STATE_2       = 2;
    localparam      STATE_3       = 3;
 // localparam      STATE_4       = 4;

//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//--------------------------------------------------------------------------------------------------------------------- 
  reg [NUM_BITS:1] r_LFSR = 0;
  reg              r_XNOR;
  // Optional Seed Value
  reg [NUM_BITS-1:0] i_Seed_Data = {NUM_BITS{128'd1}};
  reg [3:0]                  state;
 
 
//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------

  always @(posedge aclk)
    begin
      if (!aresetn)begin
        state <= STATE_INIT;
      end
      else begin
        case (state)
          STATE_INIT : begin
            state <= STATE_1;
          end
          STATE_1    : begin
            if (!pq_fifo_full) begin
              state   <=STATE_2;
            end
          end
          STATE_2    : begin
            if(r_LFSR>18'd100000 )begin
              state <= STATE_3;
            end
            else begin
              state <=STATE_1;
            end
            //odd chech
          end
          STATE_3    : begin
            state   <= STATE_1;
          end

        
          default    : begin
            //state   <= STATE_INIT;
          end   
        endcase
      end
    end

    always @(posedge aclk)
    begin
      if (!aresetn)begin
        state <= STATE_INIT;
      end
      else begin
        case (state)
          STATE_INIT : begin
            r_LFSR <= i_Seed_Data;
          end
          STATE_1    : begin
           if (!pq_fifo_full) begin
              r_LFSR <= {18'b0,r_LFSR[NUM_BITS-19:1], r_XNOR}; //18+(128-19=109)+1==128
            end
          end
        
          default    : begin
            //state   <= STATE_INIT;
          end   
        endcase
      end
    end

    always @(posedge aclk)
    begin
      if (!aresetn)begin
        pq_fifo_dout <= 1'b0;
      end
      else begin
        case (state)
   
          STATE_2    : begin
            if(r_LFSR>18'd100000 )begin
              pq_fifo_dout <= (r_LFSR*17'd65537)+2'd2; //random number reletivly prime to e value 65537  
            end
            
            //odd check
          end
        
          default    : begin
            //state   <= STATE_INIT;
          end   
        endcase
      end
    end

    always @(posedge aclk)
    begin
      if (!aresetn)begin
        state <= STATE_INIT;
      end
      else begin
        case (state)
          STATE_1 : begin
            pq_fifo_wr_en <= 1'b0;
          end
          STATE_3    : begin
            if (pq_fifo_dout%2) begin
              pq_fifo_wr_en <= 1'b1;
            end
            //pq_fifo_wr_en <= 1'b1;
          end
        
          default    : begin
            //state   <= STATE_INIT;
          end   
        endcase
      end
    end

 
  // Create Feedback Polynomials.  Based on Application Note:
  // http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
  always @(*)
    begin
      case (NUM_BITS)
        6: begin//3
          r_XNOR = r_LFSR[3] ^~ r_LFSR[2];
        end
        32: begin
          r_XNOR = r_LFSR[32] ^~ r_LFSR[22] ^~ r_LFSR[2] ^~ r_LFSR[1];
        end
        128: begin
          //r_XNOR = r_LFSR[128] ^~ r_LFSR[126] ^~ r_LFSR[101] ^~ r_LFSR[99];// this is just 128bit rng
          //128 bit rng relativly prime to value e=65537=2^16+1=~2^17, 128=17=111;111 bit* 17 bit =128 bit rng
          //r_XNOR = r_LFSR[111] ^~ r_LFSR[101];//equation values in xilinxs LFSR table 
          //110,109,98,97
          r_XNOR = r_LFSR[110] ^~ r_LFSR[109] ^~ r_LFSR[98] ^~ r_LFSR[97];
        end
 
      endcase // case (NUM_BITS)
    end // always @ (*)
    
 
  //assign pq_fifo_dout = r_LFSR[NUM_BITS:1];
 
  // Conditional Assignment (?)
  assign o_LFSR_Done = (r_LFSR[NUM_BITS:1] == i_Seed_Data) ? 1'b1 : 1'b0;
 
endmodule // rng512LFSR2