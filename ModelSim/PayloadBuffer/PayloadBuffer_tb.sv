`timescale 1ns/1ns

import PayloadBus::*;

module PayloadBuffer_tb();

    logic clock = 1'b1;
    logic reset = 1'b1;
    logic enable = 1'b0;
    logic readWrite;
    PayloadRdBus rdBus();
    PayloadWrBus wrBus();

    task Reset();
        @(posedge clock);
        reset <= 1'b1;
        @(posedge clock);
        reset <= 1'b0;
    endtask
    
    task automatic Write(
        input Data_t nodes[$],
        input Ttl_t ttl,
        input ByteCount_t byteCount,
        output Address_t address
    );
        readWrite = 1'b1;
        enable = 1'b1;
        foreach (nodes[i]) begin
            wrBus.isLast = (i == 0);
            wrBus.data = nodes[i];
            wrBus.ttl = ttl;
            wrBus.byteCount = byteCount;
            @(posedge clock);
        end
        address = wrBus.address;
        enable = 1'b0;
    endtask
    
    
    task automatic Read(
        input Address_t address,
        output Data_t nodes[$]
    );
        enable = 1'b1;
        readWrite = 1'b0;
        do begin
            $display(nodes.size());
            rdBus.isFirst = (nodes.size() == 0);
            nodes.push_back(rdBus.data);
            rdBus.address = address;
            @(posedge clock);
        end 
        while (rdBus.isLast !== 1'b1);
        enable = 1'b0;
    endtask
    

    PayloadBuffer pb (
        .clock(clock),
        .reset(reset),
        .enable(enable),
        .readWrite(readWrite),
        .rdBus(rdBus),
        .wrBus(wrBus)
    );
    
    Address_t writeAddress;
    Address_t dummyAddress;
    Data_t readNodes1[$];
    Data_t readNodes2[$];
    Data_t readNodes3[$];
    
    initial begin
        Reset();
        Write({1, 2, 3, 4}, 1, 3, writeAddress);
        Read(writeAddress, readNodes1);
        @(posedge clock);
        Write({10, 20, 30, 40}, 1, 3, dummyAddress);
        Read(writeAddress, readNodes2);
        Write({10, 20, 30, 40}, 1, 3, dummyAddress);
        $finish;
    end
    
    always begin
        #5 clock = ~clock;
    end
    
endmodule