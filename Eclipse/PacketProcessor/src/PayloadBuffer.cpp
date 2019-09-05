/*
 * PayloadBuffer.cpp
 *
 *  Created on: Aug 26, 2019
 *      Author: Anon
 */

#include "PayloadBuffer.h"

// Reads data from the payload buffer
// dst: address of the RAM buffer that will hold data
// address: address of the data in the payload buffer
// returns: Number of read bytes
uint_fast16_t PayloadBuffer::read(void* dst, uint_fast16_t address)
{
    return 0;
}

// Writes data to the payload buffer
// src: address of the RAM buffer that contains data
// length: the length of the data to be written
// returns: the address of the data in the payload buffer (buffer chooses it)
uint_fast16_t PayloadBuffer::write(void* src, uint_fast16_t length)
{
    return 100500;
}
