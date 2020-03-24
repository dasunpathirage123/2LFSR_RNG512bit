module test_prime ();
 
  parameter c_NUM_BITS = 128;
  localparam      CLK                 = 4;
  localparam      HALF_CLK            = CLK/2;
   
  reg aclk;
  reg aresetn;


   
  wire [c_NUM_BITS-1:0] pq_fifo_dout;//din to pq fifo
  wire o_LFSR_Done;
  wire pq_fifo_wr_en ;
  wire pq_fifo_full ;
  wire pq_fifo_empty;
  wire pq_fifo_rd_en ;
  wire [c_NUM_BITS-1:0] pq_fifo_din;//din to Primality test
  wire [c_NUM_BITS-1:0] prime_out;

  initial begin
    aclk                         = 0;
    forever begin      
        #(HALF_CLK)   aclk       = ~aclk;
    end
  end
  initial begin
        // Initialize Registers
        aresetn <= 1'b0;
        // Wait 100 ns for global reset to finish
        #100;
        @(posedge aclk);
        aresetn <=1'b1;
      
         

  end
   primality_top 
  #(
    .NUM_BITS(c_NUM_BITS)
    )primality_test_inst
  (
    .aclk(aclk),
    .aresetn(aresetn)
    
    );

  endmodule