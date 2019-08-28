module PayloadBuffer #(
    integer DATA_WIDTH = 32,
    integer TTL_WIDTH = 4,
    integer BUFFER_SIZE = 2048
) (
    // Clock input for this module
    input logic clock,
    
    // Synchronous reset (active when asserted)
    input logic reset,
    
    //
    output logic ready,
    
    input logic rd_enable,
    input logic [$clog2(BUFFER_SIZE)-1:0] rd_address,
    output logic [DATA_WIDTH-1:0] rd_data,
    input logic rd_first,
    input logic rd_destructive,
    output logic rd_last,
    
    input logic wr_enable,
    output logic [$clog2(BUFFER_SIZE)-1:0] wr_address,
    input [DATA_WIDTH-1:0] wr_data,
    input logic wr_first,
    input [TTL_WIDTH-1:0] wr_ttl,
    output [$clog2(BUFFER_SIZE):0] wr_capacity 
);

    typedef logic [$clog2(BUFFER_SIZE)-1:0] Address_t;
    typedef logic [$clog2(BUFFER_SIZE):0] Capacity_t;
    typedef logic [TTL_WIDTH-1:0] Ttl_t;
    typedef logic [DATA_WIDTH-1:0] Data_t;

    // Structure definition for accessing fields of blocks
    // in a more intuitive way
    typedef struct packed {
        // Actual data that is stored in the block
        Data_t data; 
        
        // Time-to-live (number of reads before the block is disposed of)
        Ttl_t ttl; 
        
        // Flag showing if the block is last in the chain
        logic last;
        
        // Pointer to the next block in the chain
        Address_t nextPtr;
    } MemEntry_t;
    
    // 
    logic resetReg;
    
    // Pointer to the last block in the free list.
    // It is used to attach deleted blocks the to free list.
    Address_t freeListTail;
    
    // BRAM related wires
    // Wires without postfixes A and B are sort of virtual and they are automatically,
    // connected to necessary memory ports depending on the current transaction.
    // For read transaction, writes are done through port A and reads through B
    // For write transaction, writes are done through port B and reads through A
    // This trick helps to keep data in the output reg of memory ports, while
    // doing another transaction, in order avoid incurring additional latency.
    // See memory instantiation at the end of this file, to understand,
    // how this port swapping works.
    
    // Memory port A definitions
    logic memA_wrEnable, memA_rdEnable;
    MemEntry_t memA_rdData, memA_wrData;
    Address_t memA_address;
    
    // Memory port B definitions
    logic memB_wrEnable, memB_rdEnable;
    MemEntry_t memB_rdData, memB_wrData;
    Address_t memB_address;
    
    // Memory addresses delayed by one clock cycle
    Address_t memA_addressReg, memB_addressReg;
    
    // Registers used for the initialization stage
    Address_t init_address, init_nextPtr;
    
    // Connect bus directly to port B to avoid MUX before outputs
    assign rd_data = memA_rdData.data;
    assign rd_last = memA_rdData.last;
    assign wr_address = memB_rdData.nextPtr;
    assign memA_wrData.ttl = wr_ttl;
    assign memA_wrData.data = wr_data;
    assign memA_wrData.last = wr_first;
    assign memB_wrData.nextPtr = memA_addressReg;
    assign memB_wrData.ttl = memA_rdData.ttl - 1'b1;

    // `reset`, `wr_enable` and `rd_enable` dependent signals
    always_comb begin
        // If module is being reset.
        // In this mode we arrange blocks in the free list,
        // by updating nextPtr trough port B.
        if (!ready) begin
            memA_wrEnable = 1'b0;
            memA_rdEnable = 1'b0;
            memB_wrEnable = 1'b1;
            memB_rdEnable = 1'b0;
        end

        // If the write transaction is selected.
        // We read free list through port B,
        // and write data trough port A.
        else if (wr_enable) begin
            memA_wrEnable = 1'b1;
            memA_rdEnable = 1'b0;
            memB_wrEnable = 1'b0;
            memB_rdEnable = 1'b1;
        end
        
        // If the read transaction is selected.
        // We read data through port B,
        // and update ttl or free list through port A
        // if it is a destructive transaction.
        else if (rd_enable) begin
            memA_wrEnable = 1'b0;
            memA_rdEnable = 1'b1;
            memB_wrEnable = rd_destructive;
            memB_rdEnable = 1'b0;
        end
        
        // If the module is disabled
        else begin
            memA_wrEnable = 1'b0;
            memA_rdEnable = 1'b0;
            memB_wrEnable = 1'b0;
            memB_rdEnable = 1'b0;
        end
    end
    
    // `reset` and `wr_enable` dependent signals
    always_comb begin
        // If module is being reset
        if (!ready) begin
            memB_address = init_address;
        end
            
        // If the write transaction is selected
        else if (wr_enable) begin
            // Traverse the free list while writing data
            // to get the next address for writing.
            memB_address = memB_rdData.nextPtr;
        end
        
        // If the read transaction is selected or module is disabled.
        else begin
            // Based on ttl we choose where to write.
            // If ttl is zero we update the last block of free list.
            // If it is not, we update ttl for the previously read block.
            // For disabled mode this assignment does not produce any effects,
            // because memA_wrEnable is disabled.
            if (memA_rdData.ttl == 1'b0) memB_address = freeListTail;
            else memB_address = memB_addressReg;
        end
    end
    
    // `reset` dependent signals
    always_comb begin
        if (!ready) begin
            // Make nextPtr of the written block
            // point to the previously written block
            memA_wrData.nextPtr = init_nextPtr;
        end
            
        // If the write mode is selected
        else begin
            // 
            memA_wrData.nextPtr = memA_addressReg;
        end
    end
    
    always_comb begin
        if (wr_enable) begin
            // Read and write at the address of free list.
            // Read happens first, so we get address of the next 
            // block of free list before we rewrite it.
            memA_address = memB_rdData.nextPtr;
        end
        
        else begin
            if (rd_first) memA_address = rd_address;
            else memA_address = memA_rdData.nextPtr;
        end
    end

    always_ff @(posedge clock) begin
        // Registers that do not need to be reset
        resetReg <= reset;
        memA_addressReg <= memA_address;
        memB_addressReg <= memB_address;
        
        // Reset behavior
        if (reset) begin
            ready <= 1'b0;
            init_address <= 1'b0;
            init_nextPtr <= 1'b1;
            wr_capacity <= Capacity_t'(BUFFER_SIZE);
            freeListTail <= Address_t'(BUFFER_SIZE - 1'b1);
        end
        
        // Initialization behavior
        else if (init_nextPtr != 2 ** $bits(Address_t) - 1'b1) begin
            init_address <= init_address + 1'b1;
            init_nextPtr <= init_nextPtr + 1'b1;
        end
        
        // Normal behavior
        else begin
            ready <= 1'b1;
             
            // If this is a write transaction
            if (wr_enable) begin
                // Reduce capacity of the buffer
                wr_capacity <= wr_capacity - 1'b1;
            end
             
            // If this is a read transaction
            else if (rd_enable) begin
                // If we need to free up a block
                if (memA_rdData.ttl == 1'b0 && !rd_first && rd_destructive) begin
                    // freeListTail should point to the block being freed up
                    freeListTail <= memA_addressReg;
                    
                    // Since we free up a block, buffer capacity increases
                    wr_capacity <= wr_capacity + 1'b1;
                end
            end
        end
    end
    
    altsyncram mem (
        .aclr0 (resetReg),
        .address_a (memA_address),
        .address_b (memB_address),
        .clock0 (clock),
        .data_a (memA_wrData),
        .data_b (memB_wrData),
        .rden_a (memA_rdEnable),
        .rden_b (memB_rdEnable),
        .wren_a (memA_wrEnable),
        .wren_b (memB_wrEnable),
        .q_a (memA_rdData),
        .q_b (memB_rdData),
        .aclr1 (1'b0),
        .addressstall_a (1'b0),
        .addressstall_b (1'b0),
        .byteena_a (1'b1),
        .byteena_b (1'b1),
        .clock1 (1'b1),
        .clocken0 (1'b1),
        .clocken1 (1'b1),
        .clocken2 (1'b1),
        .clocken3 (1'b1),
        .eccstatus ()
    );
    
    defparam
        mem.address_reg_b = "CLOCK0",
        mem.clock_enable_input_a = "BYPASS",
        mem.clock_enable_input_b = "BYPASS",
        mem.clock_enable_output_a = "BYPASS",
        mem.clock_enable_output_b = "BYPASS",
        mem.indata_reg_b = "CLOCK0",
        mem.intended_device_family = "Cyclone V",
        mem.lpm_type = "altsyncram",
        mem.numwords_a = BUFFER_SIZE,
        mem.numwords_b = BUFFER_SIZE,
        mem.operation_mode = "BIDIR_DUAL_PORT",
        mem.outdata_aclr_a = "CLEAR0",
        mem.outdata_aclr_b = "CLEAR0",
        mem.outdata_reg_a = "UNREGISTERED",
        mem.outdata_reg_b = "UNREGISTERED",
        mem.power_up_uninitialized = "FALSE",
        mem.read_during_write_mode_mixed_ports = "DONT_CARE",
        mem.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
        mem.read_during_write_mode_port_b = "NEW_DATA_NO_NBE_READ",
        mem.widthad_a = $bits(Address_t),
        mem.widthad_b = $bits(Address_t),
        mem.width_a = $bits(MemEntry_t),
        mem.width_b = $bits(MemEntry_t),
        mem.width_byteena_a = 1,
        mem.width_byteena_b = 1,
        mem.wrcontrol_wraddress_reg_b = "CLOCK0";

endmodule
