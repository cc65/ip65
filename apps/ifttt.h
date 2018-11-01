#ifndef _IFTTT_H_
#define _IFTTT_H_

#include <stdbool.h>

// Trigger IFTTT maker event via webhook
//
// Inputs: key:   Webhook key to use
//         event: Maker event to trigger
//         val1:  Webhook parameter 'value1'
//         val2:  Webhook parameter 'value2'
//         val3:  Webhook parameter 'value3'
// Output: Webhook HTTP status code, -1 on error
//
int ifttt_trigger(const char* key, const char* event,
                  const char* val1, const char* val2, const char* val3);

#endif
