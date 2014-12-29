//
//  Copyright (c) 2013 Luke Scott
//  https://github.com/lukescott/DraggableCollectionView
//  Distributed under MIT license
//

#import "LSCollectionViewHelper.h"
#import "UICollectionViewLayout_Warpable.h"
#import "UICollectionViewDataSource_DraggableWithExternalTarget.h"
#import "LSCollectionViewLayoutHelper.h"
#import <QuartzCore/QuartzCore.h>

static int kObservingCollectionViewLayoutContext;

#ifndef CGGEOMETRY__SUPPORT_H_
CG_INLINE CGPoint
_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}
CG_INLINE CGPoint
_CGPointDiff(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x - point2.x, point1.y - point2.y);
}
#endif

typedef NS_ENUM(NSInteger, _ScrollingDirection) {
    _ScrollingDirectionUnknown = 0,
    _ScrollingDirectionUp,
    _ScrollingDirectionDown,
    _ScrollingDirectionLeft,
    _ScrollingDirectionRight
};

@interface LSCollectionViewHelper ()
{
    NSIndexPath *lastIndexPath;
    UIImageView *mockCell;
    CGPoint mockCenter;
    CGPoint targetViewTranslation;
    UICollectionViewLayoutAttributes *mockLayoutAttributes;
    CGPoint fingerTranslation;
    CADisplayLink *timer;
    _ScrollingDirection scrollingDirection;
    BOOL canWarp;
    BOOL canScroll;
	BOOL _hasShouldAlterTranslationDelegateMethod;
}
@property (nonatomic, weak) UIView *inTargetView;
@property (readonly, nonatomic) LSCollectionViewLayoutHelper *layoutHelper;
@end

@implementation LSCollectionViewHelper

- (id)initWithCollectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if (self) {
        _collectionView = collectionView;
        [_collectionView addObserver:self
                          forKeyPath:@"collectionViewLayout"
                             options:0
                             context:&kObservingCollectionViewLayoutContext];
        _scrollingEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
        _scrollingSpeed = 300.f;
        
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]
                                       initWithTarget:self
                                       action:@selector(handleLongPressGesture:)];
        [_collectionView addGestureRecognizer:_longPressGestureRecognizer];
        
        _panPressGestureRecognizer = [[UIPanGestureRecognizer alloc]
                                      initWithTarget:self action:@selector(handlePanGesture:)];
        _panPressGestureRecognizer.delegate = self;
		
        // Support for UICollectionView_ExternalTarget
        _inTargetView = nil;
        
        [_collectionView addGestureRecognizer:_panPressGestureRecognizer];
        
        for (UIGestureRecognizer *gestureRecognizer in _collectionView.gestureRecognizers) {
            if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
                [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
                break;
            }
        }
        
        [self layoutChanged];
    }
    return self;
}

- (LSCollectionViewLayoutHelper *)layoutHelper
{
    return [(id <UICollectionViewLayout_Warpable>)self.collectionView.collectionViewLayout layoutHelper];
}

- (void)layoutChanged
{
    canWarp = [self.collectionView.collectionViewLayout conformsToProtocol:@protocol(UICollectionViewLayout_Warpable)];
    canScroll = [self.collectionView.collectionViewLayout respondsToSelector:@selector(scrollDirection)];
    _longPressGestureRecognizer.enabled = _panPressGestureRecognizer.enabled = canWarp && self.enabled;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kObservingCollectionViewLayoutContext) {
        [self layoutChanged];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    _longPressGestureRecognizer.enabled = canWarp && enabled;
    _panPressGestureRecognizer.enabled = canWarp && enabled;
}

- (UIImage *)imageFromCell:(UICollectionViewCell *)cell {
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0);
	[cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)invalidatesScrollTimer {
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    scrollingDirection = _ScrollingDirectionUnknown;
}

- (void)setupScrollTimerInDirection:(_ScrollingDirection)direction {
    scrollingDirection = direction;
    if (timer == nil) {
        timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
        [timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if([gestureRecognizer isEqual:_panPressGestureRecognizer]) {
        return self.layoutHelper.fromIndexPath != nil;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer isEqual:_longPressGestureRecognizer]) {
        return [otherGestureRecognizer isEqual:_panPressGestureRecognizer];
    }
    
    if ([gestureRecognizer isEqual:_panPressGestureRecognizer]) {
        return [otherGestureRecognizer isEqual:_longPressGestureRecognizer];
    }
    
    return NO;
}

- (NSIndexPath *)indexPathForItemClosestToPoint:(CGPoint)point
{
    NSArray *layoutAttrsInRect;
    NSInteger closestDist = NSIntegerMax;
    NSIndexPath *indexPath;
    NSIndexPath *toIndexPath = self.layoutHelper.toIndexPath;
    
    // We need original positions of cells
    self.layoutHelper.toIndexPath = nil;
    layoutAttrsInRect = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:self.collectionView.bounds];
    self.layoutHelper.toIndexPath = toIndexPath;
    
    // What cell are we closest to?
    for (UICollectionViewLayoutAttributes *layoutAttr in layoutAttrsInRect) {
        CGFloat xd = layoutAttr.center.x - point.x;
        CGFloat yd = layoutAttr.center.y - point.y;
        NSInteger dist = sqrtf(xd*xd + yd*yd);
        if (dist < closestDist) {
            closestDist = dist;
            indexPath = layoutAttr.indexPath;
        }
    }
    
    // Are we closer to being the last cell in a different section?
    NSInteger sections = [self.collectionView numberOfSections];
    for (NSInteger i = 0; i < sections; ++i) {
        if (i == self.layoutHelper.fromIndexPath.section) {
            continue;
        }
        NSInteger items = [self.collectionView numberOfItemsInSection:i];
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:items inSection:i];
        UICollectionViewLayoutAttributes *layoutAttr;
        CGFloat xd, yd;
        
        if (items > 0) {
            layoutAttr = [self.collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:nextIndexPath];
            xd = layoutAttr.center.x - point.x;
            yd = layoutAttr.center.y - point.y;
        } else {
            // Trying to use layoutAttributesForItemAtIndexPath while section is empty causes EXC_ARITHMETIC (division by zero items)
            // So we're going to ask for the header instead. It doesn't have to exist.
            layoutAttr = [self.collectionView.collectionViewLayout layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                                  atIndexPath:nextIndexPath];
            xd = layoutAttr.frame.origin.x - point.x;
            yd = layoutAttr.frame.origin.y - point.y;
        }
        
        NSInteger dist = sqrtf(xd*xd + yd*yd);
        if (dist < closestDist) {
            closestDist = dist;
            indexPath = layoutAttr.indexPath;
        }
    }
    
    return indexPath;
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateChanged) {
        return;
    }
    if (![self.collectionView.dataSource conformsToProtocol:@protocol(UICollectionViewDataSource_Draggable)]) {
        return;
    }
    
	_hasShouldAlterTranslationDelegateMethod = [self.collectionView.dataSource respondsToSelector:@selector(collectionView:alterTranslation:)];
	
    CGPoint ptInCollectionView = [sender locationInView:self.collectionView];
    NSIndexPath *indexPath = [self indexPathForItemClosestToPoint:ptInCollectionView];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            if (indexPath == nil) {
                return;
            }
            if (![(id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource
                  collectionView:self.collectionView
                  canMoveItemAtIndexPath:indexPath]) {
                return;
            }
            
            // Create mock cell to drag around
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            CGRect frame = cell.frame;
            cell.highlighted = NO;
            [mockCell removeFromSuperview];
            mockCell = [[UIImageView alloc] initWithFrame:frame];
            mockCell.image = [self imageFromCell:cell];

            mockCenter = mockCell.center;
            
            if ([self.collectionView.dataSource respondsToSelector:@selector(viewForDraggingFromCollectionView:)]) {
                UIView *targetView = [(id<UICollectionViewDataSource_DraggableWithExternalTarget>)self.collectionView.dataSource
                                      viewForDraggingFromCollectionView:self.collectionView];
                [targetView addSubview:mockCell];
                CGPoint ptInTargetView = [sender locationInView:targetView];
                targetViewTranslation = _CGPointDiff(ptInTargetView, ptInCollectionView);
                mockCell.center = _CGPointAdd(mockCenter, targetViewTranslation);
            }
            else {
                [self.collectionView addSubview:mockCell];
                targetViewTranslation = CGPointMake(0, 0);
            }
			if ([self.collectionView.dataSource respondsToSelector:@selector(collectionView:transformForDraggingItemAtIndexPath:duration:)]) {
				NSTimeInterval duration = 0.3;
				CGAffineTransform transform = [(id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource collectionView:self.collectionView transformForDraggingItemAtIndexPath:indexPath duration:&duration];
				[UIView animateWithDuration:duration animations:^{
					mockCell.transform = transform;
				} completion:nil];
			}
            
            self.inTargetView = nil;
            
            if ([self.collectionView.dataSource respondsToSelector:@selector(collectionView:willBeginDragOfIndex:)] == YES)
            {
                [(id<UICollectionViewDataSource_Draggable>)
                 self.collectionView.dataSource collectionView:self.collectionView
                                          willBeginDragOfIndex:indexPath];
            }
            
            // Start warping
            lastIndexPath = indexPath;
            self.layoutHelper.fromIndexPath = indexPath;
            self.layoutHelper.hideIndexPath = indexPath;
            self.layoutHelper.toIndexPath = indexPath;
            [self.collectionView.collectionViewLayout invalidateLayout];
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if(self.layoutHelper.fromIndexPath == nil) {
                return;
            }
            
            // special case for the external target view, if supported
            if (self.inTargetView)
            {
                
                if ([self.collectionView.dataSource
                     conformsToProtocol:@protocol(UICollectionViewDataSource_DraggableWithExternalTarget)])
                {
                    id<UICollectionViewDataSource_DraggableWithExternalTarget>delegate = (id<UICollectionViewDataSource_DraggableWithExternalTarget>)self.collectionView.dataSource;
                    if ([delegate respondsToSelector:@selector(collectionView:leaveTarget:fromIndexPath:)]) {
                        [delegate collectionView:self.collectionView leaveTarget:_inTargetView fromIndexPath:self.layoutHelper.fromIndexPath];
                    }

                    if ([delegate respondsToSelector:@selector(collectionView:willEndDragOfIndex:)] == YES) {
                        [delegate collectionView:self.collectionView willEndDragOfIndex:self.layoutHelper.fromIndexPath];
                    }
                    
                    [delegate collectionView:self.collectionView
                                didHitTarget:_inTargetView
                                     atPoint:[sender locationInView:_inTargetView]
                               fromIndexPath:self.layoutHelper.fromIndexPath];
                }
                
                self.inTargetView = nil;
                self.layoutHelper.fromIndexPath = nil;
                self.layoutHelper.toIndexPath = nil;
                
                [mockCell removeFromSuperview];
                mockCell = nil;
                mockLayoutAttributes = nil;
                self.layoutHelper.hideIndexPath = nil;
                [self.collectionView.collectionViewLayout invalidateLayout];
            }
            else
            {
                if ([self.collectionView.dataSource respondsToSelector:@selector(collectionView:willEndDragOfIndex:)] == YES)
                {
                    [(id<UICollectionViewDataSource_Draggable>)
                     self.collectionView.dataSource collectionView:self.collectionView
                                                willEndDragOfIndex:self.layoutHelper.fromIndexPath];
                }
                
                // Tell the data source to move the item
                [(id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource collectionView:self.collectionView
                                                                                     moveItemAtIndexPath:self.layoutHelper.fromIndexPath
                                                                                             toIndexPath:self.layoutHelper.toIndexPath];
                
                // Move the item
                [self.collectionView performBatchUpdates:^{
                    [self.collectionView moveItemAtIndexPath:self.layoutHelper.fromIndexPath toIndexPath:self.layoutHelper.toIndexPath];
                    self.layoutHelper.fromIndexPath = nil;
                    self.layoutHelper.toIndexPath = nil;
                } completion:nil];
                
            }
            
            // Switch mock for cell
            UICollectionViewLayoutAttributes *layoutAttributes = [self.collectionView layoutAttributesForItemAtIndexPath:self.layoutHelper.hideIndexPath];
            [UIView
             animateWithDuration:0.3
             animations:^{
                 mockCell.center = _CGPointAdd(layoutAttributes.center, targetViewTranslation);
                 mockCell.transform = CGAffineTransformMakeScale(1.f, 1.f);
             }
             completion:^(BOOL finished) {
                 [mockCell removeFromSuperview];
                 mockCell = nil;
                 mockLayoutAttributes = nil;
                 self.layoutHelper.hideIndexPath = nil;
                 [self.collectionView.collectionViewLayout invalidateLayout];
             }];

            // Reset
            [self invalidatesScrollTimer];
            lastIndexPath = nil;
            
        } break;
        default: break;
    }
}

- (void)warpToIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath == nil || [lastIndexPath isEqual:indexPath]) {
        return;
    }
    lastIndexPath = indexPath;
    
    if ([self.collectionView.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:toIndexPath:)] == YES
        && [(id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource
            collectionView:self.collectionView
            canMoveItemAtIndexPath:self.layoutHelper.fromIndexPath
            toIndexPath:indexPath] == NO) {
			return;
		}
    
    [self.collectionView performBatchUpdates:^{
        self.layoutHelper.hideIndexPath = indexPath;
        self.layoutHelper.toIndexPath = indexPath;
    } completion:nil];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender
{
    if(sender.state == UIGestureRecognizerStateChanged) {
        // Move mock to match finger
        fingerTranslation = [sender translationInView:self.collectionView.superview];
		if (_hasShouldAlterTranslationDelegateMethod) {
			[(id<UICollectionViewDataSource_Draggable>)self.collectionView.dataSource collectionView:self.collectionView alterTranslation:&fingerTranslation];
		}
        CGPoint translatedCentre = _CGPointAdd(mockCenter, fingerTranslation);
        mockCell.center = _CGPointAdd(translatedCentre, targetViewTranslation);

        // special case for the external target view, if supported
        if ([self.collectionView.dataSource
             conformsToProtocol:@protocol(UICollectionViewDataSource_DraggableWithExternalTarget)])
        {
            id<UICollectionViewDataSource_DraggableWithExternalTarget> delegate = (id<UICollectionViewDataSource_DraggableWithExternalTarget>)self.collectionView.dataSource;
            __block UIView *nextTargetView = nil;
            CGPoint pt = [sender locationInView:self.collectionView.superview];
            [[delegate externalTargetsForCollectionView:self.collectionView] enumerateObjectsUsingBlock:^(UIView *targetView, NSUInteger idx, BOOL *stop) {
                if (CGRectContainsPoint(targetView.frame, pt)) {
                    nextTargetView = targetView;
                    *stop = YES;
                }
            }];
            
            if (nextTargetView) {
                if (![nextTargetView isEqual:_inTargetView]) {
                    if (_inTargetView
                        && [delegate respondsToSelector:@selector(collectionView:leaveTarget:fromIndexPath:)]) {
                        [delegate collectionView:self.collectionView leaveTarget:_inTargetView fromIndexPath:self.layoutHelper.fromIndexPath];
                    }
                    if ([delegate respondsToSelector:@selector(collectionView:enterTarget:atPoint:fromIndexPath:)]) {
                        [delegate collectionView:self.collectionView enterTarget:nextTargetView
                                         atPoint:[sender locationInView:nextTargetView] fromIndexPath:self.layoutHelper.fromIndexPath];
                    }
                }
                else if ([delegate respondsToSelector:@selector(collectionView:dragInTarget:atPoint:fromIndexPath:)]) {
                    [delegate collectionView:self.collectionView dragInTarget:nextTargetView
                                     atPoint:[sender locationInView:nextTargetView] fromIndexPath:self.layoutHelper.fromIndexPath];
                }
                self.inTargetView = nextTargetView;
            }
            else {
                if (_inTargetView
                    && [delegate respondsToSelector:@selector(collectionView:leaveTarget:fromIndexPath:)]) {
                    [delegate collectionView:self.collectionView leaveTarget:_inTargetView fromIndexPath:self.layoutHelper.fromIndexPath];
                }
                self.inTargetView = nil;
            }
        }
        
        // Scroll when necessary
        if (canScroll) {
            UICollectionViewFlowLayout *scrollLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
            if([scrollLayout scrollDirection] == UICollectionViewScrollDirectionVertical) {
                if (translatedCentre.y < (CGRectGetMinY(self.collectionView.bounds) + self.scrollingEdgeInsets.top)) {
                    [self setupScrollTimerInDirection:_ScrollingDirectionUp];
                }
                else {
                    if (translatedCentre.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingEdgeInsets.bottom)) {
                        [self setupScrollTimerInDirection:_ScrollingDirectionDown];
                    }
                    else {
                        [self invalidatesScrollTimer];
                    }
                }
            }
            else {
                if (translatedCentre.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingEdgeInsets.left)) {
                    [self setupScrollTimerInDirection:_ScrollingDirectionLeft];
                } else {
                    if (translatedCentre.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingEdgeInsets.right)) {
                        [self setupScrollTimerInDirection:_ScrollingDirectionRight];
                    } else {
                        [self invalidatesScrollTimer];
                    }
                }
            }
        }
        
        // Avoid warping a second time while scrolling
        if (scrollingDirection > _ScrollingDirectionUnknown) {
            return;
        }
        
        // Warp item to finger location
        CGPoint point = [sender locationInView:self.collectionView];
        NSIndexPath *indexPath = [self indexPathForItemClosestToPoint:point];
        [self warpToIndexPath:indexPath];
    }
}

- (void)handleScroll:(NSTimer *)timer {
    if (scrollingDirection == _ScrollingDirectionUnknown) {
        return;
    }
    
    CGSize frameSize = self.collectionView.bounds.size;
    CGSize contentSize = self.collectionView.contentSize;
    CGPoint contentOffset = self.collectionView.contentOffset;
    CGFloat distance = self.scrollingSpeed / 60.f;
    CGPoint translation = CGPointZero;

    switch(scrollingDirection) {
        case _ScrollingDirectionUp: {
            distance = -distance;
            if ((contentOffset.y + distance) <= 0.f) {
                distance = 0.f - contentOffset.y;
            }
            translation = CGPointMake(0.f, distance);
        } break;
        case _ScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height;
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
            translation = CGPointMake(0.f, distance);
        } break;
        case _ScrollingDirectionLeft: {
            distance = -distance;
            if ((contentOffset.x + distance) <= 0.f) {
                distance = -contentOffset.x;
            }
            translation = CGPointMake(distance, 0.f);
        } break;
        case _ScrollingDirectionRight: {
            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width;
            if ((contentOffset.x + distance) >= maxX) {
                distance = maxX - contentOffset.x;
            }
            translation = CGPointMake(distance, 0.f);
        } break;
        default: break;
    }
    
    mockCenter  = _CGPointAdd(mockCenter, translation);
    targetViewTranslation = _CGPointDiff(targetViewTranslation, translation);
    mockCell.center = _CGPointAdd(_CGPointAdd(mockCenter, fingerTranslation), targetViewTranslation);
    self.collectionView.contentOffset = _CGPointAdd(contentOffset, translation);

    // Warp items while scrolling
    NSIndexPath *indexPath = [self indexPathForItemClosestToPoint:mockCenter];
    [self warpToIndexPath:indexPath];
}

@end
