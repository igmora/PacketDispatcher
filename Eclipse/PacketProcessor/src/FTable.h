/*
 * FTable.h
 *
 *  Created on: Aug 26, 2019
 *      Author: Anon
 */
#ifndef FTABLE_H_
#define FTABLE_H_

#include <stdint.h>
#include "PacketHeader.h"
#include "FTableEntry.h"

struct FTable
{
    static const FTableEntry table[];
};

#endif /* FTABLE_H_ */
