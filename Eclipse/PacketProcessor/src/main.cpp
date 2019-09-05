/*
 * test.cpp
 *
 *  Created on: Aug 23, 2019
 *      Author: Anon
 */

#include <stdint.h>
#include <stddef.h>
#include "FTable.h"
#include "PayloadBuffer.h"
#include "PacketHeader.h"
#include "sys/alt_stdio.h"

//int main()
//{
//  alt_putstr("Hello from Nios II!\n");
//
//  // Event loop never exits.
//  while (1);
//
//  return 0;
//}
//
//using namespace std;

//extern FTableEntry* FTable;

// RAM buffer for storing the input received from the payload buffer
uint8_t inBuffer[512];

// RAM buffer for storing the output before sending it to the payload buffer
uint8_t outBuffer[512];

int main()
{
    PacketHeader p;
    PacketHeader::write(p);

    while(1)
    {
        // Read the next header from the queue
    	// This call is blocking
        PacketHeader::read(p);

        // Find the entry we need in the function table
        FTableEntry entry = FTable::table[p.id.localId];

        // If packet requires computation (not NO_CHANGE packet)
        if (!p.nc)
        {
            uint_fast16_t outSize, inSize;

            // Read data from the payload buffer
            inSize = PayloadBuffer::read(inBuffer, p.ptr1);

            // Run the function. If it returns false, turn packet into a NO_CHANGE one
            p.nc = !entry.transform(inBuffer, inSize, outBuffer, outSize);

            // Write the processed data to the payload buffer
            // Put the address of the data to the header
            p.ptr1 = PayloadBuffer::write(outBuffer, outSize);
        }

        // Assign new id to packet header
        p.id = entry.newId;

        // Send packet header to the destination
        //PacketHeader::write(p);

        // Hang here
        while(1);
    }
}
