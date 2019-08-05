package PayloadBus;

    typedef logic [11:0] Address_t;
    typedef logic [$bits(Address_t):0] Capacity_t;
    typedef logic [3:0] Ttl_t;
    typedef logic [1:0] ByteCount_t;
    typedef logic [31:0] Data_t;

endpackage