/*
 * FTableEntry.h
 *
 *  Created on: Aug 30, 2019
 *      Author: Anon
 */

#ifndef FTABLEENTRY_H_
#define FTABLEENTRY_H_

#include "PacketId.h"

// Entry of the function table
struct FTableEntry
{
    //
    typedef bool (*Transform_t)(void*, uint_fast16_t, void*, uint_fast16_t&);

    //
    const PacketId newId;

    //
    const Transform_t transform;

    FTableEntry(PacketId, Transform_t);
};

#endif /* FTABLEENTRY_H_ */
