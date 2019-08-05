import PayloadBus::*;

// Interface for performing read transactions to the PayloadBuffer
interface PayloadRdBus();

    // Master sets it to '1' when sending
    // the the address of the chain it wants to read.
    // When reading the blocks it has to be '0'.
    logic isFirst;
    
    // Through this port master sends
    // the address of the chain it wants to read
    Address_t address;
    
    // If master sets it to '1' during a read transaction,
    // ttl of each block is decremented during this read.
    // If ttl is already 0, the blocks of the chain will be
    // deleted by attaching them to the free list.
    // If master sets it to '0' the read transaction
    // will not affect ttl and the block will not be removed.
    logic isDestructive;
    
    // Slave uses this port to show how many bytes
    // of the current block are valid 
    ByteCount_t byteCount;
    
    // Data provided by the slave
    Data_t data;
    
    // Slave sets this port to '1' to show that
    // the current block is the last in the chain.
    // After reading the last block, master have to
    // stop the reading transaction by deasserting 
    // the enable signal or starting a new transaction.
    logic isLast;
    
    modport Slave (
        input isFirst,
        input address,
        input isDestructive,
        output data,
        output byteCount,
        output isLast
    );
    
    modport Master (
        output isFirst,
        output address,
        output isDestructive,
        input data,
        input byteCount,
        input isLast
    );
    
endinterface