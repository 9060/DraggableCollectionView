//
//  Copyright (c) 2013 Luke Scott
//  https://github.com/lukescott/DraggableCollectionView
//  Distributed under MIT license
//

#import <UIKit/UIKit.h>
#import "UICollectionViewDataSource_Draggable.h"
#import "UICollectionViewDataSource_ExternalTarget.h"

@interface UICollectionView (Draggable)

@property (nonatomic, assign) BOOL draggable;
@property (nonatomic, assign) UIEdgeInsets scrollingEdgeInsets;
@property (nonatomic, assign) CGFloat scrollingSpeed;

- (NSIndexPath *)indexPathForItemClosestToPoint:(CGPoint)point;

@end
