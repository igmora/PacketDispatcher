import PayloadBus::*;

module PayloadBuffer(
    input logic clock,
    input logic reset,
    input logic enable,
    input logic readWrite,
    PayloadRdBus.Slave rdBus,
    PayloadWrBus.Slave wrBus
);

    typedef struct packed {
        Data_t data;
        Ttl_t ttl;
        ByteCount_t byteCount;
        logic isLast;
        Address_t nextPtr;
    } MemEntry_t;
    
    MemEntry_t memRdData, memWrData;
    Address_t freePtr, memRdAddressReg, memWrAddressReg;
    Address_t memRdAddress, memWrAddress;
    logic memWriteEnable;
    Address_t nextFreePtr;
    
    assign rdBus.byteCount = memRdData.byteCount;
    assign rdBus.data = memRdData.data;
    assign rdBus.isLast = memRdData.isLast;
    
    assign nextFreePtr = wrBus.isLast ? freePtr : memRdData.nextPtr;

    always_comb begin
        // If the read mode is selected
        if (!readWrite) begin
            // Rewrite data on each read, so that we can update ttl only
            // TODO: use separate memory for ttl, so that the rest of the data
            // is not rewritten every time. This may save some energy.
            memWrData = memRdData;
            
            // Set write address such that we update the data
            // that was read on the previous CC
            memWrAddress <= memRdAddressReg;
 
            // If we do the read of the first block in the chain
            if (rdBus.isFirst) begin
                // We do not write anything at this first stage
                memWriteEnable <= 'b0;
                
                // At the first stage of the read mode
                // we use the address received from the bus
                memRdAddress <= rdBus.address;
            end
            
            // For each next stage .
            // That is how we walk through the linked list.
            else begin
                // 
                memWriteEnable <= enable;
                
                // Use the address obtained from the previous read
                // to walk through the linked list 
                memRdAddress <= memRdData.nextPtr;

                if (memRdData.ttl == 'b0)
                    memWrData.nextPtr = freePtr;
                else
                    memWrData.ttl = memRdData.ttl - 1'b1;
            end

        end
        
        // If the write mode is selected
        else begin
            memWriteEnable <= enable;
            memWrData.nextPtr <= memRdAddressReg;
            memWrData.ttl <= wrBus.ttl;
            memWrData.data <= wrBus.data;
            memWrData.isLast <= wrBus.isLast;
            memWrData.byteCount <= wrBus.byteCount;
            memWrAddress <= nextFreePtr;
            memRdAddress <= nextFreePtr;
        end
    end


    always_ff @(posedge clock) begin
        // Reset behavior
        if (reset) begin
            freePtr <= 'b0;
        end
        
        // Non-reset behavior
        else if (enable) begin
            // Save the previous value of memRdAddress
            memRdAddressReg <= memRdAddress;

            if (readWrite) begin
                freePtr <= memRdData.nextPtr;
                wrBus.address <= nextFreePtr;
            end

            else begin
                if (memRdData.ttl == 'b0) begin
                    freePtr <= memRdAddressReg;
                end
            end
        end
    end
    
    altsyncram mem (
        .address_a (memWrAddress),
        .address_b (memRdAddress),
        .clock0 (clock),
        .data_a (memWrData),
        .wren_a (memWriteEnable),
        .q_b (memRdData),
        .aclr0 (1'b0),
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
        .data_b ({$bits(MemEntry_t){1'b1}}),
        .eccstatus (),
        .q_a (),
        .rden_a (1'b1),
        .rden_b (1'b1),
        .wren_b (1'b0));
        
    defparam
        mem.address_aclr_b = "NONE",
        mem.address_reg_b = "CLOCK0",
        mem.clock_enable_input_a = "BYPASS",
        mem.clock_enable_input_b = "BYPASS",
        mem.clock_enable_output_b = "BYPASS",
        mem.init_file = "../../Quartus/PacketDispatcher/src/PayloadBuffer.mif",
        mem.intended_device_family = "Cyclone V",
        mem.lpm_type = "altsyncram",
        mem.numwords_a = 4096,
        mem.numwords_b = 4096,
        mem.operation_mode = "DUAL_PORT",
        mem.outdata_aclr_b = "NONE",
        mem.outdata_reg_b = "UNREGISTERED",
        mem.power_up_uninitialized = "FALSE",
        mem.read_during_write_mode_mixed_ports = "OLD_DATA",
        mem.widthad_a = $bits(Address_t),
        mem.widthad_b = $bits(Address_t),
        mem.width_a = $bits(MemEntry_t),
        mem.width_b = $bits(MemEntry_t),
        mem.width_byteena_a = 1;

endmodule
