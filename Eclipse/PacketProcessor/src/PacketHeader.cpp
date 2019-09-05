/*
 * PacketHeader.cpp
 *
 *  Created on: Aug 28, 2019
 *      Author: Anon
 */

#include "system.h"
#include "PacketHeader.h"
#include "sys/alt_stdio.h"
#include "altera_avalon_fifo_util.h"
#include "altera_avalon_mutex.h"

#define IN_BASE HEADER_QUEUE_IN_BASE
#define OUT_BASE HEADER_QUEUE_OUT_BASE
#define OUT_CSR_BASE HEADER_QUEUE_OUT_CSR_BASE

// Initialize mutex
// We are not using mutex_open, because it involves some
// overhead related to string processing
static alt_mutex_dev mutex = {0, 0, 0, (void*)(HEADER_QUEUE_MUTEX_BASE)};

void PacketHeader::read(PacketHeader& ph)
{
    // Lock mutex, so that other cores cannot access the queue
    // We need this because the queue has the control interface
    // (for testing emptiness) and the data interface.
    // They cannot be accessed atomically
    altera_avalon_mutex_lock(&mutex, 1);
    
    // Wait until there is a packet header in the queue 
    while(altera_avalon_fifo_read_status(OUT_CSR_BASE, ALTERA_AVALON_FIFO_STATUS_E_MSK));
    
    // Read header from the queue
    int rawData = IORD_ALTERA_AVALON_FIFO_DATA(OUT_BASE);
    
    // Unlock the mutex, so that other cores can have access to the queue
    altera_avalon_mutex_unlock(&mutex);

    // Parse data received from the queue
    // Use fake parsing for now
    ph.id = PacketId(0, 0);
    ph.nc = false;
    ph.seq = 0;
    ph.ptr1 = 0;
}

void PacketHeader::write(const PacketHeader& ph)
{
    // Fake implementation
	int rawData = 0;

    // Select packet destination
    switch(ph.id.dest)
    {
        case 0:
        	IOWR_ALTERA_AVALON_FIFO_DATA(IN_BASE, rawData);
            break;

    }
};
