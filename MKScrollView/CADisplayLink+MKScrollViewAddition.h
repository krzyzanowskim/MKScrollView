//
//  CADisplayLink+Decelerating.h
//
//  Created by Marcin Krzyzanowski on 30/03/14.
//  Copyright (c) 2014 Marcin Krzyżanowski All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CADisplayLink (MKScrollViewAddition)
@property (strong, nonatomic) id mk_userInfo;
@property (assign, nonatomic, readwrite) BOOL mk_isDecelerating;
@property (assign, nonatomic) CFTimeInterval mk_lastTimeStamp;
@end
