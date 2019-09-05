/*
 * PacketHeader.h
 *
 *  Created on: Aug 27, 2019
 *      Author: Anon
 */



#ifndef PACKETID_H_
#define PACKETID_H_

#include <stdint.h>

struct PacketId
{
    uint_fast8_t dest;
    uint_fast8_t localId;

    PacketId(uint_fast8_t, uint_fast8_t);
    PacketId();
};

#endif /* PACKETID_H_ */

