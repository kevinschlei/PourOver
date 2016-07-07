//
//  POPdBase.h
//  libpdCocoapods
//
//  Created by labuser on 7/25/14.
//  Copyright (c) 2014 Kevin Schlei. All rights reserved.
//

#import "PdBase.h"

@protocol POPdListener
@optional
- (void)receiveFloat:(float)received fromConstCharSource:(const char *)source;
- (void)receiveList:(NSArray *)received fromConstCharSource:(const char *)source;
- (void)receiveTwoValueListValueA:(float)valueA valueB:(float)valueB fromConstCharSource:(const char *)source;
- (void)receiveThreeValueListValueA:(float)valueA valueB:(float)valueB valueC:(float)valueC fromConstCharSource:(const char *)source;
- (void)psrControllerRequest:(const char *)controller;

@end

@interface POPdBase : PdBase

+ (int)sendBangToConstCharReceiver:(const char *)receiverName;
+ (void)sendFloat:(float)value toConstCharReceiver:(const char *)receiverName;
+ (int)sendFloatList:(float *)list count:(int)count toConstCharReceiver:(const char *)receiverName;

@end
