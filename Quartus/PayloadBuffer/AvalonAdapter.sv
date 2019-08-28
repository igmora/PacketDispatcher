module AvalonAdapter #(
    integer DATA_WIDTH = 32,
    integer TTL_WIDTH = 4,
    integer BUFFER_SIZE = 2048
) 

(
    // Clock input for this module
    input logic clock,
    
    // Synchronous reset (active when asserted)
    input logic reset,
    
    output logic ready,
    
    // Alvalon-MM slave for accessing control registers
    input logic csr_write,
    input logic [31:0] csr_writedata,
    output logic [31:0] csr_readdata,

    // Avalon-ST source for reading data from the buffer
    output logic [DATA_WIDTH-1:0] src_data,
    output logic src_valid,
    input logic src_ready,
    output logic src_startofpacket,
    output logic src_endofpacket,

    // Avalon-ST sink for writing data to the buffer
    input logic [DATA_WIDTH-1:0] snk_data,
    input logic snk_valid,
    output logic snk_ready,
    input logic snk_startofpacket,
    input logic snk_endofpacket
);

    typedef logic [$clog2(BUFFER_SIZE)-1:0] Address_t;
    typedef logic [$clog2(BUFFER_SIZE):0] Capacity_t;
    typedef logic [TTL_WIDTH-1:0] Ttl_t;
    typedef logic [DATA_WIDTH-1:0] Data_t;

    // Control Register 0 structure
    typedef struct packed {
        Address_t address;
        Capacity_t capacity;
        Ttl_t ttl;
        logic destructive;
    } CR0_t;
    
    localparam int CR0_RESERVED = 32 - $bits(CR0_t);
    
    // Control Register 0
    CR0_t cr0;
    
    // PayloadBuffer related nets
    logic pb_rd_enable, pb_rd_first, pb_rd_destructive, pb_rd_last;
    logic pb_wr_enable, pb_wr_first;
    Address_t pb_rd_address, pb_wr_address;
    Data_t pb_rd_data, pb_wr_data;
    Capacity_t pb_wr_capacity;
    Ttl_t pb_wr_ttl;
    
    assign pb_wr_enable = snk_valid;
    assign pb_wr_first = snk_startofpacket;
    assign pb_wr_data = snk_data;
    assign pb_wr_ttl = cr0.ttl;
    assign pb_rd_enable = src_ready;
    assign pb_rd_first = src_startofpacket;
    assign pb_rd_address = cr0.address;
    assign pb_rd_destructive = cr0.destructive;
    assign src_endofpacket = pb_rd_last;
    assign snk_ready = 1'b1;
    assign src_data = pb_rd_data;
    assign csr_readdata = {cr0, {CR0_RESERVED{1'b1}}};

    always_ff @(posedge clock) begin
        // Reset behavior
        if (reset) begin
            cr0 <= CR0_t'(0);
            src_startofpacket <= 1'b0;
            src_valid <= 1'b0;
        end
        
        // Write to buffer
        else if (snk_valid) begin
            cr0.address <= pb_wr_address;
        end
            
        // Read from buffer
        else if (src_ready) begin
            // If it is the address providing stage
            if (!src_valid) begin
                src_startofpacket <= 1'b1;
                src_valid <= 1'b1;
            end
            
            // If it is the data providing stage
            else begin
                src_startofpacket <= 1'b0;
                if (src_endofpacket) src_valid <= 1'b0;
            end
        end
        
        // Update control register from the bus
        else if (csr_write) begin
            cr0 <= csr_writedata;
        end
    end
    
    PayloadBuffer pb (
        .clock(clock),
        .reset(reset),
        .ready(ready),
        
        .rd_enable(pb_rd_enable),
        .rd_address(pb_rd_address),
        .rd_data(pb_rd_data),
        .rd_first(pb_rd_first),
        .rd_destructive(pb_rd_destructive),
        .rd_last(pb_rd_last),
        
        .wr_enable(pb_wr_enable),
        .wr_address(pb_wr_address),
        .wr_data(pb_wr_data),
        .wr_first(pb_wr_first),
        .wr_ttl(pb_wr_ttl),
        .wr_capacity(pb_wr_capacity)
    );
    
    defparam
        pb.DATA_WIDTH = DATA_WIDTH,
        pb.TTL_WIDTH = TTL_WIDTH,
        pb.BUFFER_SIZE = BUFFER_SIZE;

endmodule