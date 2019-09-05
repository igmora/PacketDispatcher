/*
 * PacketHeader.cpp
 *
 *  Created on: Aug 28, 2019
 *      Author: Anon
 */

#include "PacketId.h"

PacketId::PacketId(uint_fast8_t _dest, uint_fast8_t _localId) :
        dest(_dest),
        localId(_localId) { }

PacketId::PacketId() : dest(0), localId(0) { }
