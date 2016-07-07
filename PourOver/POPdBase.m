//
//  POPdBase.m
//  libpdCocoapods
//
//  Created by labuser on 7/25/14.
//  Copyright (c) 2014 Kevin Schlei. All rights reserved.
//

#import "POPdBase.h"

#include "z_libpd.h"
#include "z_queued.h"
#include "z_print_util.h"

/*
 cyclone
 note: do not add standalone.c to target; it just duplicates existing pd source
 */
extern void allnettles_setup(void);
extern void allhammers_setup(void);
extern void allsickles_setup(void);

@implementation POPdBase

+ (void)initialize
{
	[super initialize];
    
	libpd_set_queued_floathook(bsFloatHook);
	libpd_set_queued_listhook(bsListHook);
    
    //cyclone ([svf~])
    allnettles_setup();
    allhammers_setup();
    allsickles_setup();
}

+ (int)sendBangToConstCharReceiver:(const char *)receiverName
{
	@synchronized([PdBase class]) {
		return libpd_bang(receiverName);
	}
}

+ (void)sendFloat:(float)value toConstCharReceiver:(const char *)receiverName
{
	@synchronized([PdBase class]) {
		libpd_float(receiverName, value);
	}
}

+ (int)sendFloatList:(float *)list count:(int)count toConstCharReceiver:(const char *)receiverName
{
	@synchronized([PdBase class]) {
		if (libpd_start_message(count)) return -100;
		for (int i = 0; i < count; i++) {
			libpd_add_float(list[i]);
		}
		return libpd_finish_list(receiverName);
	}
}

static void bsFloatHook(const char *src, float x)
{
	if ([[PdBase delegate] respondsToSelector:@selector(receiveFloat:fromConstCharSource:)]) {
		[(id<POPdListener>)[PdBase delegate] receiveFloat:x fromConstCharSource:src];
	}
}

static void bsListHook(const char *src, int argc, t_atom *argv) {
    if (argc == 2) {
        if ([[PdBase delegate] respondsToSelector:@selector(receiveTwoValueListValueA:valueB:fromConstCharSource:)]) {
            t_atom *a = &argv[0];
            t_atom *b = &argv[1];
            [(id<POPdListener>)[PdBase delegate] receiveTwoValueListValueA:a->a_w.w_float valueB:b->a_w.w_float fromConstCharSource:src];
        }
    }
    else if (argc == 3) {
        if ([[PdBase delegate] respondsToSelector:@selector(receiveThreeValueListValueA:valueB:valueC:fromConstCharSource:)]) {
            t_atom *a = &argv[0];
            t_atom *b = &argv[1];
            t_atom *c = &argv[2];
            [(id<POPdListener>)[PdBase delegate] receiveThreeValueListValueA:a->a_w.w_float valueB:b->a_w.w_float  valueC:c->a_w.w_float fromConstCharSource:src];
        }
    }
}

void psrControllerRequest(const char *controller) {
    if ([[PdBase delegate] respondsToSelector:@selector(psrControllerRequest:)]) {
        [(id<POPdListener>)[PdBase delegate] psrControllerRequest:controller];
    }
}

@end
