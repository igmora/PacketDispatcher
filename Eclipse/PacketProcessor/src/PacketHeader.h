/*
 * PacketHeader.h
 *
 *  Created on: Aug 27, 2019
 *      Author: Anon
 */



#ifndef PACKETHEADER_H_
#define PACKETHEADER_H_

#include <stdint.h>
#include "PacketId.h"

struct PacketHeader
{
    PacketId id;
    uint_fast8_t seq;
    bool nc;
    uint_fast16_t ptr1;
    uint_fast16_t ptr2;

    static void read(PacketHeader&);
    static void write(const PacketHeader&);
};

#endif /* PACKETHEADER_H_ */

