//
//  MKScrollView.h
//
//  Created by Marcin Krzyzanowski on 10/04/14.
//  Copyright (c) 2014 Marcin Krzyżanowski All rights reserved.
//

#import <UIKit/UIKit.h>

@class MKScrollView;

@protocol MKScrollViewDelegate <NSObject>

@optional
- (void)scrollViewDidScroll:(MKScrollView *)scrollView; // any offset changes
- (void)scrollViewDidEndDragging:(MKScrollView *)scrollView willDecelerate:(BOOL)decelerate; // called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
- (void)scrollViewDidEndDecelerating:(MKScrollView *)scrollView; // called when scroll view grinds to a halt
@end

@interface MKScrollView : UIView

@property (assign, nonatomic, readonly, getter = isDecelerating) BOOL decelerating;
@property (assign, nonatomic, getter           = isScrollEnabled) BOOL scrollEnabled;
@property (assign, nonatomic) CGSize       contentSize;//By default size of layer
@property (assign, nonatomic) CGPoint      contentOffset;
@property (assign, nonatomic) UIEdgeInsets contentInset;//The distance that the content view is inset from the enclosing scroll view.
@property (assign, nonatomic) BOOL         pagingEnabled;// not working yet

@property (weak) IBOutlet id <MKScrollViewDelegate> delegate;

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated duration:(CGFloat)duration;

@end
