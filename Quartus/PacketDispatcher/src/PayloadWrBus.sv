import PayloadBus::*;

// Interface for performing write transactions to the PayloadBuffer
interface PayloadWrBus();

    // Master sets this to '1' for the first block it writes
    logic isLast;
    
    // Data written by the master
    Data_t data;
    
    // Time-to-live that master sets for the blocks
    // must be the same for all blocks in a chain
    Ttl_t ttl;
    
    // Master uses this port to show how many bytes
    // of the current block are valid 
    ByteCount_t byteCount;
    
    // Slave uses this port to transfer the address
    // at which is it is going to write data.
    // Useful during the last write cycle, because
    // it gives the pointer to the linked list that has been written
    Address_t address;
    
    // Shows how many blocks are available in the buffer
    Capacity_t capacity;

    modport Slave (
        input isLast,
        input data,
        input ttl,
        input byteCount,
        output address,
        output capacity
    );
    
    modport Master (
        output isLast,
        output data,
        output ttl,
        output byteCount,
        input address,
        input capacity
    );
    
endinterface