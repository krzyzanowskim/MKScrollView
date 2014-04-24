//
//  CADisplayLink+Decelerating.m
//
//  Created by Marcin Krzyzanowski on 30/03/14.
//  Copyright (c) 2014 Marcin Krzyżanowski All rights reserved.
//

#import "CADisplayLink+MKScrollViewAddition.h"
#import <objc/runtime.h>

@implementation CADisplayLink (MKScrollViewAddition)

@dynamic mk_userInfo;
@dynamic mk_isDecelerating;
@dynamic mk_lastTimeStamp;

- (id)mk_userInfo
{
    id val = objc_getAssociatedObject(self, "userInfo");
    return val;
}

- (void)setMk_userInfo:(id)userInfo
{
    objc_setAssociatedObject(self, "userInfo", userInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)mk_isDecelerating
{
    id val = objc_getAssociatedObject(self, "isDecelerating");
    return [val boolValue];
}

- (void)setMk_isDecelerating:(BOOL)isDecelerating
{
    objc_setAssociatedObject(self, "isDecelerating", @(isDecelerating), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CFTimeInterval)mk_lastTimeStamp
{
    id val = objc_getAssociatedObject(self, "lastTimeStamp");
    return [val doubleValue];
}

- (void)setMk_lastTimeStamp:(CFTimeInterval)lastTimeStamp
{
    objc_setAssociatedObject(self, "lastTimeStamp", @(lastTimeStamp), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
