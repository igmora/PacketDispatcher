/*
 * FTable_generated.cpp
 *
 *  Created on: Aug 26, 2019
 *      Author: Anon
 */

#include "FTable.h"

// This file should be generated from user-designed diagrams


// Adds 2 to the integer input and produces integer
// These functions can work as both filter and map
// The map part takes data from rawIn, processes it and and puts it to rawOut
// The filter part decides whether return true or false
// For true packet is processed normally
// For false packet is turned into NO_CHANGE packet, meaning it was filtered out
// The prototype of is not very is not very convenient for the user to work with,
// because they need to manually convert pointers. Later we can make some sort of wrapper using
// C++ templates, so the user works with the data types they need instead of raw pointers. 
bool add2(void* rawIn, uint_fast16_t inSize, void* rawOut, uint_fast16_t& outSize)
{
    int* inData = static_cast<int*>(rawIn);
    int* outData = static_cast<int*>(rawOut);

    *outData = *inData + 2;
    outSize = sizeof(int);

    return true;
}

// Add 2 to the float input 
bool add2f(void* rawIn, uint_fast16_t inSize, void* rawOut, uint_fast16_t& outSize)
{
    float* inData = static_cast<float*>(rawIn);
    float* outData = static_cast<float*>(rawOut);

    *outData = *inData + 2;
    outSize = sizeof(int);

    return true;
}

// Function table example
// Format: output_id, function
const FTableEntry FTable::table[] =
{
    FTableEntry(PacketId(0, 1), add2),
    FTableEntry(PacketId(0, 0), add2f)
};
