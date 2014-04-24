//
//  MKScrollView.m
//
//  Created by Marcin Krzyzanowski on 10/04/14.
//  Copyright (c) 2014 Marcin Krzyżanowski All rights reserved.
//
// TODO: pagingEnabled
// TODO: bounces
// TODO: directionalLockEnabled
// TODO: scrollIndicators

#ifdef DEBUG
#define SCROLLVIEW_VERBOSE 1
#endif

#import "MKScrollView.h"
#import "CADisplayLink+MKScrollViewAddition.h"

static NSString * const kMKScrollViewVerticalDirection = @"vertical";
static NSString * const kMKScrollViewHorizontalDirection = @"horizontal";

@interface MKScrollView ()

@property (assign) CGSize internalContentSize; // contentSize + insets
@end

@implementation MKScrollView {
    CGPoint         _moveVelocity;
    NSTimeInterval  _previousTouchMoveEventTimeStamp;
    CADisplayLink   *_displayLink;

    CGSize          _contentSize;

    @package
    struct {
        unsigned int moveBegan:1;
    } _flags;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self initialSettings];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initialSettings];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initialSettings];
    }
    return self;
}

static char * contentSizeContext = "context";

- (void) initialSettings
{
    self.scrollEnabled  = YES;
    self.exclusiveTouch = NO;

    [self addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:contentSizeContext];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"contentSize"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // update internal content size whenever content size is updated
    if (context == contentSizeContext && [keyPath isEqualToString:@"contentSize"]) {
        [self updateInternalContentSize];
    }
}

- (void)didAddSubview:(UIView *)subview
{
    [super didAddSubview:subview];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL ret = [super gestureRecognizerShouldBegin:gestureRecognizer];
    return ret;
}

#pragma mark - Properties

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    _contentInset = contentInset;
    [self updateInternalContentSize]; // Update content size with new content inset in scope
}

- (CGSize)contentSize
{
    if (CGSizeEqualToSize(_contentSize, CGSizeZero)) {
        self.contentSize = self.layer.bounds.size;
    }
    return _contentSize;
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
    [self setContentOffset:contentOffset animated:animated duration:(animated ? 0.35f : 0.0f)];
}

- (void)setContentOffset:(CGPoint)contentOffsetOrig animated:(BOOL)animated duration:(CGFloat)duration
{
    CGPoint contentOffset = CGPointMake(-contentOffsetOrig.x, -contentOffsetOrig.y);

    void (^updateBounds)(void) = ^void(void) {
        [self setLayerBounds:(CGRect) {
            .origin = contentOffset,
            .size = self.bounds.size
        }];
    };

    if (animated) {
        [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionCurveLinear animations:^{
            updateBounds();
        } completion:^(BOOL finished) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
                [self.delegate scrollViewDidScroll:self];
            }
        }];
    } else {
        updateBounds();

        if (self.delegate && [self.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
            [self.delegate scrollViewDidScroll:self];
        }
    }
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    [self setContentOffset:contentOffset animated:NO];
}

- (CGPoint)contentOffset
{
    return self.layer.bounds.origin;
}

- (BOOL)isDecelerating
{
    return _displayLink.mk_isDecelerating;
}

# pragma mark - Touches

// unused
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.exclusiveTouch) {
        [super touchesBegan:touches withEvent:event];
    }

    [_displayLink invalidate];
}


// There seems to be delay between touchesBegan and touchesModes so I ignore touchesBegan and use _moveBegan flag
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.exclusiveTouch) {
        [super touchesMoved:touches withEvent:event];
    }

    if (!self.scrollEnabled)
        return;

    // Reset for the very beginning
    if (_flags.moveBegan) {
        _moveVelocity                    = CGPointZero;
        _previousTouchMoveEventTimeStamp = 0;
    }

    NSTimeInterval eventTimeStamp = event.timestamp;

    UITouch *touch       = [[event allTouches] anyObject];
    CGPoint currentPoint = [touch locationInView:self.superview];
    CGPoint prevPoint    = [touch previousLocationInView:self.superview];

    CGVector changeVector = CGVectorMake(currentPoint.x - prevPoint.x, currentPoint.y - prevPoint.y);

    NSTimeInterval timeInterval = (eventTimeStamp - _previousTouchMoveEventTimeStamp);
#ifdef SCROLLVIEW_VERBOSE
    NSLog(@"touchesMoved (%@,%@)->(%@,%@) [%@,%@] t=(%@)", @(prevPoint.x), @(prevPoint.y), @(currentPoint.x), @(currentPoint.y), @(changeVector.dx), @(changeVector.dy), @(timeInterval));
#endif

    if (_previousTouchMoveEventTimeStamp > 0 && timeInterval > 0.0 ) {
        CGFloat velocityX = changeVector.dx / (timeInterval);
        CGFloat velocityY = changeVector.dy / (timeInterval);
#ifdef SCROLLVIEW_VERBOSE
        NSLog(@"velocity (%@,%@)", @(velocityX), @(velocityY));
#endif
        _moveVelocity = CGPointMake(velocityX, velocityY);
    }

    // check if in content size
    CGPoint newContentOffset = (CGPoint) {-(self.contentOffset.x - changeVector.dx), -(self.contentOffset.y - changeVector.dy)};

    NSLog(@"newContentOffset (%@,%@)",@(newContentOffset.x), @(newContentOffset.y));
    // Check boundaries
    if ((newContentOffset.x + self.bounds.size.width <= self.internalContentSize.width) &&
        (newContentOffset.y + self.bounds.size.height <= self.internalContentSize.height) &&
        newContentOffset.x >= 0.0 &&
        newContentOffset.y >= 0.0)
    {
        [self setContentOffset:newContentOffset];
    } else {
        [self alignFromOffset:newContentOffset velocity:_moveVelocity];
    }

    _previousTouchMoveEventTimeStamp = eventTimeStamp;
    _flags.moveBegan = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    _flags.moveBegan = YES;

    if (!self.exclusiveTouch) {
        [super touchesEnded:touches withEvent:event];
    }

    NSTimeInterval eventTimeStamp = event.timestamp;

#ifdef SCROLLVIEW_VERBOSE
    NSLog(@"touchesEnded %@, time %@", @(touches.count), @(eventTimeStamp - _previousTouchMoveEventTimeStamp));
#endif

    // decelerate at the end
    BOOL willDecelerate = !self.pagingEnabled;
    willDecelerate = willDecelerate && (_moveVelocity.x != 0 || _moveVelocity.y != 0);
    willDecelerate = willDecelerate && (eventTimeStamp - _previousTouchMoveEventTimeStamp < 0.1);
    willDecelerate = willDecelerate && !CGSizeEqualToSize(self.internalContentSize, self.bounds.size);

    if (self.delegate && [self.delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.delegate scrollViewDidEndDragging:self willDecelerate:willDecelerate];
    }
    
    if (willDecelerate) {
        [self decelerateWithVelocity:_moveVelocity withCompletionBlock:^(BOOL finished, CGPoint distance, CGPoint velocity) {
            CGPoint newContentOffset = CGPointMake(-(self.contentOffset.x - distance.x), -(self.contentOffset.y - distance.y));

            // Check limits
            if ((newContentOffset.x + self.bounds.size.width <= self.internalContentSize.width) &&
                (newContentOffset.y + self.bounds.size.height <= self.internalContentSize.height) &&
                newContentOffset.x >= 0.0 &&
                newContentOffset.y >= 0.0)
            {
                [self setContentOffset:newContentOffset];
            } else {
                [_displayLink invalidate];
                finished = YES;
                [self alignFromOffset:newContentOffset velocity:velocity];
            }

            if (finished) {
                [_displayLink invalidate];
                if (self.delegate && [self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
                    [self.delegate scrollViewDidEndDecelerating:self];
                }
            }
        }];
    }

    if (self.pagingEnabled) {
        //TODO: snap to edges
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.exclusiveTouch) {
        [super touchesCancelled:touches withEvent:event];
    }
#if SCROLLVIEW_DEBUG
    NSLog(@"touchesCancelled %@", @(touches.count));
#endif
    [_displayLink invalidate];
}

// see headers:
//- (CGRect)alignmentRectForFrame:(CGRect)frame NS_AVAILABLE_IOS(6_0);
//- (CGRect)frameForAlignmentRect:(CGRect)alignmentRect NS_AVAILABLE_IOS(6_0);


#pragma mark - Deceleration

- (void)decelerateWithVelocity:(CGPoint)velocity withCompletionBlock:(void(^)(BOOL finished, CGPoint distance, CGPoint velocity))completionBlock
{
    NSMutableDictionary *userInfo = [@{@"velocity" : [NSValue valueWithCGPoint:velocity]} mutableCopy];
    if (completionBlock)
    {
        userInfo[@"completionBlock"] = completionBlock;
    }

    [_displayLink invalidate];
    _displayLink = nil;
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(decelerateStep:)];
    _displayLink.frameInterval = 1;
    _displayLink.mk_userInfo = userInfo;
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)decelerateStep:(CADisplayLink *)timer
{
    if (timer.mk_isDecelerating) {
        return;
    }
    timer.mk_isDecelerating = YES;

    void (^completionBlock)(BOOL finished, CGPoint distance, CGPoint velocity) = timer.mk_userInfo[@"completionBlock"];

    CGPoint velocity = [timer.mk_userInfo[@"velocity"] CGPointValue];
    velocity.y *= 0.9f;
    velocity.x *= 0.9f;
    timer.mk_userInfo[@"velocity"] = [NSValue valueWithCGPoint:velocity];

    if (timer.mk_lastTimeStamp == 0) {
        timer.mk_lastTimeStamp = timer.timestamp;
    }

    CFTimeInterval timePassed = (timer.timestamp - timer.mk_lastTimeStamp);
    timer.mk_lastTimeStamp = timer.timestamp;

    CGPoint distance;
    distance.y = velocity.y * timePassed;
    distance.x = velocity.x * timePassed;
    if(ABS(velocity.y) <= 0.1 && ABS(velocity.x) <= 0.1)
    {
        timer.mk_isDecelerating = NO;
        [timer invalidate];
        if (timer.mk_userInfo[@"completionBlock"])
        {
            if (completionBlock) {
                completionBlock(YES, distance, velocity);
            }
        }
        return;
    }

    if (completionBlock) {
        completionBlock(NO, distance, velocity);
    }

    timer.mk_isDecelerating = NO;
}

#pragma mark - Private

- (void) updateInternalContentSize
{
    self.internalContentSize = CGSizeMake(self.contentSize.width + (self.contentInset.left + self.contentInset.right),
                                          self.contentSize.height + self.contentInset.top + self.contentInset.bottom);

}

- (void) alignFromOffset:(CGPoint)newContentOffset velocity:(CGPoint)velocity
{
    CGPoint alignPoint = [self alignPoint:newContentOffset];

    // Calculate align animation duration
    CGFloat distanceX = ABS(newContentOffset.x - alignPoint.x);
    CGFloat distanceY = ABS(newContentOffset.y - alignPoint.y);

    CGFloat durationX = ABS(distanceX / velocity.x);
    CGFloat durationY = ABS(distanceY / velocity.y);

    // Move with animation
    CGFloat duration = MAX(durationX, durationY);
    if (ABS(duration) > 0.01) {
        [self setContentOffset:alignPoint animated:YES duration:duration];
    } else {
        [self setContentOffset:alignPoint];
    }
}

- (CGPoint) alignPoint:(CGPoint)newContentOffset
{
    CGFloat alignedX = newContentOffset.x;
    CGFloat alignedY = newContentOffset.y;

    if (newContentOffset.x < 0.0) {
        alignedX = 0;
    }

    if (newContentOffset.x + self.bounds.size.width > self.internalContentSize.width) {
        alignedX = self.internalContentSize.width - self.bounds.size.width;
    }

    if (newContentOffset.y < 0.0) {
        alignedY = 0;
    }

    if (newContentOffset.y + self.bounds.size.height > self.internalContentSize.height) {
        alignedY = self.internalContentSize.height - self.bounds.size.height;
    }

    return CGPointMake(alignedX, alignedY);
}

// Changing the bounds size grows or shrinks the view relative to its center point.
- (void) setLayerBounds:(CGRect) newBounds
{
    CGPoint prevFrameOrig = self.layer.frame.origin;
    self.layer.bounds = newBounds;
    self.layer.frame = (CGRect) {
        .origin = prevFrameOrig,
        .size   = self.layer.frame.size
    };
}

- (CGRect) convenrtRectToUIKit:(CGRect)rect inRect:(CGRect)container
{
    CGRect frame = rect;
    frame.origin.y = container.size.height - frame.origin.y - frame.size.height;
    return frame;
}

- (CGPoint) convertPointToUIKit:(CGPoint)point fromPoint:(CGSize)containerSize
{
    CGPoint frame = point;
    frame.y = containerSize.height - frame.y;
    return frame;
}

@end
