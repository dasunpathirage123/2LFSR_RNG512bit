`timescale 1ns / 1ps

module primality_test 
  #(
    parameter NUM_BITS = 128
   )(

   input 				 aclk,
   input 				 aresetn,

   output reg[NUM_BITS-1:0]  prime_out,
				
   output reg				 pq_fifo_rd_en,
   input[NUM_BITS-1:0]	 pq_fifo_din,
   input				 pq_fifo_empty
   );

    localparam      STATE_INIT  = 0;
    localparam      SET_P       = 1;
    localparam      GET_M       = 2;
    localparam      SET_A       = 3;
    localparam      GET_X       = 4;
    localparam      CHECK_1     = 5;
    localparam      LOOP        = 6;
    localparam      LOOP_CHECK  = 7;

//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//--------------------------------------------------------------------------------------------------------------------- 
reg 					   p_valid;
reg [NUM_BITS-1:0]		   p_value;
reg 					   a_valid;
reg [NUM_BITS-1:0]	 	   a_value;

wire 					x_valid;
wire [NUM_BITS-1:0]	    x_value      ;
reg  [NUM_BITS-1:0]     x_data;
reg  [NUM_BITS-1:0]     x_out;
reg [3:0]               state;
wire [NUM_BITS-1:0]     m_value;
wire 					m_valid; 
reg  [NUM_BITS-1:0]     m;
reg  [32:0] 			security_value;
//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------


always @(posedge aclk ) begin 
	if(!aresetn) begin
		 state <= STATE_INIT;
	end else begin
		 case (state)
		 	STATE_INIT		: begin
		 		if (!pq_fifo_empty) begin
		 			state <= SET_P;
		 		end
		 	end

		 	SET_P			: begin
		 		state <= GET_M;
		 	end

		 	GET_M			: begin
		 		if (m_valid) begin
		 			state <= SET_A;
		 		end
		 	end

		 	SET_A			: begin
		 		if (security_value != 32'd0 && !pq_fifo_empty) begin
		 			state <= GET_X;
		 		end else if (pq_fifo_empty && security_value != 32'd0) begin
		 			state <= SET_A;;
		 		end else begin
		 			state <= STATE_INIT;
		 		end
		 	end

		 	GET_X			: begin
		 		if (x_valid) begin
		 			state <= CHECK_1;
		 		end
		 	end

		 	CHECK_1			: begin
		 		if (x_data == 128'b1 || x_data == p_value - 128'b1) begin
		 			state <= SET_A;
		 			//posibility to be prime
		 		end else begin
		 			state <= LOOP;
		 		end
		 	end

		 	LOOP			: begin
		 		if (m == p_value - 128'b1) begin
		 			state <= STATE_INIT;
		 		end else begin
		 			state <= LOOP_CHECK;
		 		end
		 	end

		 	LOOP_CHECK		: begin
		 		if (x_data == p_value -128'b1) begin
		 			state <= SET_A;
		 			//posibility to be prime
		 		end else
		 		if (x_data == 128'b1) begin
		 			state  <= STATE_INIT;
		 		end else begin
		 			state  <= LOOP;
		 		end
		 	end

		 	default : /* default */;
		 endcase
	end
end

// set p value (random number)
always @(posedge aclk ) begin 
	if(!aresetn) begin
		pq_fifo_rd_en <= 1'b0;
		p_valid 	  <= 1'b0;
	end else begin
		 case (state)
		 	SET_P			: begin
		 		pq_fifo_rd_en <= 1'b1;
		 		p_valid 	  <= 1'b1;
		 		p_value 	  <= pq_fifo_din;
		 	end

		 	GET_M			: begin
		 		pq_fifo_rd_en <= 1'b0;
		 		p_valid 	  <= 1'b0;
		 	end

		 	default : /* default */;
		 endcase
	end
end

//get m value
always @(posedge aclk ) begin 
	if(!aresetn) begin
		m <= 1'b0;
	end else begin
		 case (state)

		 	SET_A			: begin
	 			m  <= m_value;
		 	end
		 	default : /* default */;
		 endcase
	end
end

//set a random
always @(posedge aclk ) begin 
	if(!aresetn) begin
		 a_valid		  <= 1'b0;
	end else begin
		 case (state)

		 	SET_A			: begin
		 		if (security_value != 32'd0 && !pq_fifo_empty) begin
		 			pq_fifo_rd_en <= 1'b1;
			 		a_valid		  <= 1'b1;
			 		a_value		  <= pq_fifo_din%(p_value-2) + 2;
		 		end
		 		
		 	end

		 	GET_X			: begin
		 		a_valid		  <= 1'b0;
		 		pq_fifo_rd_en <= 1'b0;
		 	end

		 	default : /* default */;
		 endcase
	end
end

always @(posedge aclk ) begin 
	if(!aresetn) begin
		 x_out  <= 128'b0;
	end else begin
		 case (state)

		 	SET_A			: begin
		 		if (security_value != 32'd0 && !pq_fifo_empty) begin
		 			
		 		end else if (pq_fifo_empty && security_value != 32'd0) begin
		 			
		 		end else begin
		 			x_out <= x_data;
		 		end
		 		
		 	end


		 	default : /* default */;
		 endcase
	end
end

//set security value
always @(posedge aclk ) begin 
	if(!aresetn) begin
		 security_value <= 32'd10;
	end else begin
		 case (state)
		 	STATE_INIT		: begin
		 		security_value <= 32'd10;
		 	end


		 	SET_A			: begin
		 		if (security_value != 32'd0 && !pq_fifo_empty) begin
		 			security_value <= security_value - 32'b1;
		 		end 
		 	end

		 	

		 	default : /* default */;
		 endcase
	end
end

// get x value
always @(posedge aclk ) begin 
	if(!aresetn) begin
		 state <= STATE_INIT;
	end else begin
		 case (state)

		 	GET_X			: begin
		 		if (x_valid) begin
		 			x_data <= x_value;
		 		end
		 	end

		 	default : /* default */;
		 endcase
	end
end

//loop m multipling and x multipling
always @(posedge aclk ) begin 
	if(!aresetn) begin
		 state <= STATE_INIT;
	end else begin
		 case (state)
		 	STATE_INIT		: begin
		 		x_data <= 128'b1;
		 	end

		 	LOOP			: begin
		 		x_data <= (x_data * x_data ) % p_value;
		 		m      <= m*2'd2;
		 	end

	

		 	default : /* default */;
		 endcase
	end
end



mod_power_m
#(
	.BIT_LENGTH(NUM_BITS)
	) mod_power_m_inst
(
	.aclk   (aclk  ),   
	.aresetn(aresetn),
	.p_value(p_value),
	.p_valid(p_valid),
	.a_valid(a_valid),
	.a_value(a_value),
	.m_valid(m_valid),
	.m_value(m_value),
	.x_valid(x_valid),
	.x_value(x_value)          
	);

endmodule 