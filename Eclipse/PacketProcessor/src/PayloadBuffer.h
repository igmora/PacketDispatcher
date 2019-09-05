/*
 * PayloadBuffer.h
 *
 *  Created on: Aug 26, 2019
 *      Author: Anon
 */

#ifndef PAYLOADBUFFER_H_
#define PAYLOADBUFFER_H_

#include <stdint.h>

class PayloadBuffer
{
public:
    static uint_fast16_t read(void*, uint_fast16_t);
    static uint_fast16_t write(void*, uint_fast16_t);
};


#endif /* PAYLOADBUFFER_H_ */
