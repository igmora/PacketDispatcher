import PayloadBus::*;

module PayloadBuffer(
    // Clock input for this module
    input logic clock,
    
    // Synchronous reset (active when asserted)
    input logic reset,
    
    // Assert this signal before doing read or write transaction
    input logic enable,
    
    // Set to '1' for write transaction and to '0' for reading
    input logic readWrite,
    
    // Interface for performing read transactions
    // (see description in PayloadRdBus.sv)
    PayloadRdBus.Slave rdBus,
    
    // Interface for performing write transactions
    // (see description in PayloadWrBus.sv)
    PayloadWrBus.Slave wrBus
);

    // Number of blocks this buffer can store.
    // For increasing buffer size change the definition
    // of Address_t in PayloadBus.sv
    localparam int BUFFER_SIZE = 2 ** $bits(Address_t);

    // Structure definition for accessing fields of blocks
    // in a more intuitive way
    typedef struct packed {
        // Actual data that is stored in the block
        Data_t data; 
        
        // Time-to-live (number of reads before the block is disposed of)
        Ttl_t ttl; 
        
        // byteCount+1 is the number of valid bytes
        // in the data section of the block.
        // It makes sense to set it to values less than 3
        // only for the last block in the chain.
        ByteCount_t byteCount;   
        
        // Flag showing if the block is last in the chain
        logic isLast;
        
        // Pointer to the next block in the chain
        Address_t nextPtr;
    } MemEntry_t;
    
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
    logic memWrEnable, memRdEnable;
    Address_t memWrAddress, memRdAddress;
    MemEntry_t memRdData, memWrData;
    MemEntry_t memRdDataA, memRdDataB;
    
    // Memory addressed delayed by one clock cycle
    Address_t memRdAddressReg, memWrAddressReg;
    
    // Connect bus directly to port B to avoid MUX before outputs
    assign rdBus.byteCount = memRdDataA.byteCount;
    assign rdBus.data = memRdDataA.data;
    assign rdBus.isLast = memRdDataA.isLast;
    assign wrBus.address = memRdDataB.nextPtr;

    // This comb logic is used to properly connect memory inputs
    // and outputs together depending on the chosen mode
    always_comb begin
        // If the write mode is selected
        if (readWrite == 1'b1) begin
            // This is for writing data
            memWrEnable = enable;
            
            // This is for reading nextPtr
            // It points to the next block in free list
            memRdEnable = enable;
            
            // Read and write at the address of free list.
            // Read happens first, so we get address of the next 
            // block of free list before we rewrite it.
            memRdAddress = memRdData.nextPtr;
            memWrAddress = memRdData.nextPtr;
            
            // Make nextPtr of the written block
            // point to the previously written block
            memWrData.nextPtr = memWrAddressReg;
            
            // Get data from the bus
            // TODO: connecting them directly to mem port
            // may remove a MUX
            memWrData.ttl = wrBus.ttl;
            memWrData.data = wrBus.data;
            memWrData.isLast = wrBus.isLast;
            memWrData.byteCount = wrBus.byteCount;
        end

        // If the read mode is selected
        else begin
            // Rewrite data after each read in order to modify ttl
            // ttl itself is override later in this block
            memWrData = memRdData;
            
            // Write to the location we previously read from
            memWrAddress = memRdAddressReg; 
            
            // Read is always enabled
            memRdEnable = enable;
            
            // This may be enabled later in this block
            // depending on the reading stage and mode
            memWrEnable = 1'b0;
            
            // If we read the first block in a chain
            if (rdBus.isFirst) begin
                // At the first stage of the read mode
                // we use the address received from the bus
                memRdAddress = rdBus.address;
            end
            
            // If it is any other stage
            else begin
                // Use the address obtained from the previous read
                // to walk through the linked list 
                memRdAddress = memRdData.nextPtr;

                // If read transaction is destructive
                if (rdBus.isDestructive) begin
                    // We need to enable writing to update ttl or free up the block
                    memWrEnable = enable;
                
                    // If we need to free up the block
                    if (memRdData.ttl == 1'b0) begin
                        // Update the tail of the free list
                        // so that it points to the block we are removing
                        memWrAddress = freeListTail;
                        memWrData.nextPtr = memRdAddressReg;
                    end
                    
                    // If we need to decrement ttl
                    else begin
                        // Update ttl in the block read previously
                        memWrAddress = memRdAddressReg;
                        memWrData.ttl = memRdData.ttl - 1'b1;
                    end
                end
            end
        end
    end

    always_ff @(posedge clock) begin
        // Reset behavior
        if (reset) begin
            wrBus.capacity <= Capacity_t'(BUFFER_SIZE);
            freeListTail <= Address_t'(BUFFER_SIZE - 1'b1);
            memWrAddressReg <= 1'b0;
            memRdAddressReg <= 1'b0;
        end
        
        // Non-reset behavior
        else if (enable) begin
            // Save the previous values of addresses
            memWrAddressReg <= memWrAddress;
            memRdAddressReg <= memRdAddress;
            
            // If this is a read transaction
            if (readWrite == 1'b0) begin
                // If we need to free up a block
                if (memRdData.ttl == 1'b0 && !rdBus.isFirst && rdBus.isDestructive) begin
                    // freeListTail should point to the block being freed up
                    freeListTail <= memRdAddressReg;
                    
                    // Since we free up a block, buffer capacity increases
                    wrBus.capacity <= wrBus.capacity + 1'b1;
                end
            end
            
            // If this is a write transaction
            else begin
                // Reduce capacity of the buffer
                wrBus.capacity <= wrBus.capacity - 1'b1;
            end
        end
    end
    
    assign memRdData = readWrite ? memRdDataB : memRdDataA;
    altsyncram mem (
        .aclr0 (1'b0),
        .address_a (readWrite ? memWrAddress : memRdAddress),
        .address_b (readWrite ? memRdAddress : memWrAddress),
        .clock0 (clock),
        .data_a (memWrData),
        .data_b (memWrData),
        .rden_a (readWrite ? 1'b0 : memRdEnable),
        .rden_b (readWrite ? memRdEnable : 1'b0),
        .wren_a (readWrite ? memWrEnable : 1'b0),
        .wren_b (readWrite ? 1'b0 : memWrEnable),
        .q_a (memRdDataA),
        .q_b (memRdDataB),
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
        mem.init_file = "../../Quartus/PacketDispatcher/src/PayloadBuffer.mif",
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
