import PayloadBus::*;

interface PayloadWrBus();
    logic isLast;
    Data_t data;
    Ttl_t ttl;
    ByteCount_t byteCount;
    Address_t address;

    modport Slave (
        input isLast,
        input data,
        input ttl,
        input byteCount,
        output address
    );
    
    modport Master (
        output isLast,
        output data,
        output ttl,
        output byteCount,
        input address
    );
endinterface