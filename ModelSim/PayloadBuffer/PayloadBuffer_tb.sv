`timescale 1ns/1ns

import PayloadBus::*;

module PayloadBuffer_tb();

    logic clock = 1'b1;
    logic reset = 1'b1;
    logic enable = 1'b0;
    logic readWrite = 1'b0;
    PayloadRdBus rdBus();
    PayloadWrBus wrBus();

    task automatic Reset();
        @(posedge clock);
        reset <= 1'b0;
    endtask
    
    task automatic Write(input Data_t nodes[$]);
        readWrite = 1'b1;
        enable = 1'b1;
        foreach (nodes[i]) begin
            wrBus.isLast = (i == 0);
            wrBus.data = nodes[i];
            @(posedge clock);
        end
        enable = 1'b0;
    endtask
    
    
    task automatic Read(output Data_t nodes[$]);
        enable = 1'b1;
        readWrite = 1'b0;
        do begin
            rdBus.isFirst = (nodes.size() == 0);
            nodes.push_back(rdBus.data);
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
    
    Data_t readNodes[$];
    
    initial begin
        Reset();
        
        wrBus.ttl = 1;
        wrBus.byteCount = 3;
        Write({400, 300, 200, 100});
        
        rdBus.address = wrBus.address;
        rdBus.isDestructive = 1'b1;
        readNodes = {};
        Read(readNodes);
        
        wrBus.ttl = 0;
        wrBus.byteCount = 3;
        Write({10, 20, 30, 40});
        
        readNodes = {};
        Read(readNodes);
        
        wrBus.ttl = 0;
        wrBus.byteCount = 3;
        Write({10, 20, 30, 40});
        //$finish;
    end
    
    always begin
        #5 clock = ~clock;
    end
    
endmodule