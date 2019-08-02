import PayloadBus::*;

interface PayloadRdBus();
    logic isFirst;
    Address_t address;
    ByteCount_t byteCount;
    Data_t data;
    logic isLast;
    logic isDestructive;
    
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