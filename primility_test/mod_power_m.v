`timescale 1ns / 1ps

module mod_power_m
#(
	parameter BIT_LENGTH = 128
)(
	input 						aclk,    // Clock
	input 						aresetn,  // Asynchronous reset active low
	
	input  [BIT_LENGTH-1:0]		p_value,
	input						p_valid,
	
	input						a_valid,
	input  [BIT_LENGTH-1:0]		a_value,

	output reg					m_valid,
	output reg[BIT_LENGTH-1:0]  m_value,
	
	output reg					x_valid,
	output reg [BIT_LENGTH-1:0] x_value
	
);

    localparam      STATE_INIT_M   = 0;
    localparam      STATE_1M       = 1;
    localparam      STATE_2M       = 2;
    localparam      STATE_3M       = 3;


    localparam      STATE_INIT_X   = 0;
    localparam      STATE_1X       = 1;
    localparam      STATE_2X       = 2;
    localparam      STATE_3X       = 3;
 
//---------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//--------------------------------------------------------------------------------------------------------------------- 
reg [3:0]                  state_m;
reg [3:0]                  state_x;
//reg[BIT_LENGTH-1:0]  	   m_value;
wire 					   p_valid;
wire [BIT_LENGTH-1:0]	   p_value;
wire 					   a_valid;
wire [BIT_LENGTH-1:0]	   a_value;
//wire   					   x_valid;
//wire [BIT_LENGTH-1:0] 	   x_value;

reg [BIT_LENGTH-1:0]	   m;
reg [BIT_LENGTH-1:0]	   x;


//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------
/*always @(posedge aclk) 
begin 
	if(!aresetn) begin
	a_availble <= 1'b0;
	end else begin
		if (a_valid) begin
			a_availble <= 1'b1;
		end
	
	end
end

always @(posedge aclk ) 
begin 
	if(!aresetn) begin
		state <= STATE_INIT;
		output_data_x <= 128'd1;
		output_data_valid_x <= 1'b0;
	end else begin
		case (state)
			STATE_INIT : begin
				output_data_x <= 128'd1;
				if (p_valid) begin
					state <= STATE_1;
					m_value <=p_value-1;//even value
				end else begin
					state <= STATE_INIT;
				end
			end
			STATE_1    : begin
				if (!((m_value)%2)) begin
					state 	<= STATE_2;
				end else begin
					state   <= STATE_3;
				end
			end
			STATE_2    : begin
				m_value <=	m_value/2'd2;
				state   <=	STATE_1;
			end
			STATE_3    : begin
				m_out <= m_value;
				if (a_availble) begin
					state <= STATE_4;
					a_availble <= 1'b0;
					x_data <= a_value%p_value;
				end else begin
					state <= STATE_3;
				end
			end
			STATE_4    : begin
				if ((m_value)%2) begin
					output_data_x <= (output_data_x*x_data)%p_value;
					m_value <= m_value - 1'b1;
					state <= STATE_5;
				end else begin
					state <= STATE_5;
				end
			end
			STATE_5    : begin
				x_data <= (x_data*x_data)%p_value;
				m_value <= m_value/2;
				if (m_value == 1'b0) begin
					state <= STATE_6;
				end else begin
					state <= STATE_4;
				end
			end
			STATE_6   : begin
				output_data_valid_x <= 1'b1;
				state <= STATE_INIT;
			end
		
			default : /* default ;
		endcase
	end
end*/

//calculate m_value // p-1=m*(2^r),m?
always @(posedge aclk ) begin 
	if(!aresetn) begin
		state_m <= STATE_INIT_M; 
	end else begin
		 case (state_m)
		 
		 STATE_INIT_M		: begin
		 	if (p_valid) begin
		 		state_m <= STATE_1M;
		 	end else begin
		 		state_m <= STATE_INIT_M;
		 	end
		 end

		 STATE_1M 		: begin
		 	if (!(m%2)) begin
		 		state_m <= STATE_2M;
		 	end else begin
		 		state_m <= STATE_3M;
		 	end
		 end

		 STATE_2M		: begin
		 	state_m <= STATE_1M;
		 end

		 STATE_3M 		: begin
		 	state_m 	<= STATE_INIT_M;
		 end
		 	default : /* default */;
		 endcase
	end
end

//m value
always @(posedge aclk ) begin 
	if(!aresetn) begin
		m_value <= 128'b0;
		m 		<= 128'b1;
	end else begin
		 case (state_m)
		 
		 STATE_INIT_M		: begin
		 	m_valid	<= 1'b0;
		 	if (p_valid) begin
		 		m <= p_value - 1'b1;
		 	end 
		 end


		 STATE_2M		: begin
		 	m <= m / 2'd2;
		 end

		 STATE_3M 		: begin
		 	m_value <= m;
		 	m_valid	<= 1'b1;
		 end
		 	default : /* default */;
		 endcase
	end
end

//calculate x value
always @(posedge aclk) begin 
	if(!aresetn) begin
		 state_x <= STATE_INIT_X;
	end else begin
		case (state_x)
			STATE_INIT_X	: begin 
				if (a_valid) begin
					state_x <= STATE_1X; 
				end
			end
			STATE_1X		: begin
				//if (m%2) begin
					state_x <= STATE_2X;
				//end
			end
			STATE_2X		: begin
				if (m==128'b0) begin
					state_x <= STATE_3X;
				end else begin
					state_x <= STATE_1X;
				end
			end
			STATE_3X		: begin
				state_x <= STATE_INIT_X;
			end
		
			default : /* default */;
		endcase
	end
end


always @(posedge aclk) begin 
	if(!aresetn) begin
		 x_valid <= 1'b0;
		 x_value <= 128'b1;
		 x 		 <= 128'b1;
	end else begin
		case (state_x)
			STATE_INIT_X	: begin 
				x_valid <= 1'b0;
				if (a_valid) begin
					x <= a_value % p_value; 
					x_value <= 128'b1;
					m 		<=	m_value;
				end
			end
			STATE_1X		: begin
				if (m%2) begin
					m <= m - 128'b1;
					x_value <= (x_value * x)%p_value;
				end
			end
			STATE_2X		: begin
				m = m / 2'd2;
				x = (x *x)%p_value;
				$display("TEST PASED, expected %d, result %d", x, x%p_value);
			end
			STATE_3X		: begin
				x_valid <= 1'b1;
			end
		
			default : /* default */;
		endcase
	end
end


endmodule