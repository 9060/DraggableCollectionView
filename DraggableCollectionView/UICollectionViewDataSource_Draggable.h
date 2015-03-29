//
//  Copyright (c) 2013 Luke Scott
//  https://github.com/lukescott/DraggableCollectionView
//  Distributed under MIT license
//

#import <Foundation/Foundation.h>

@class LSCollectionViewHelper;

@protocol UICollectionViewDataSource_Draggable <UICollectionViewDataSource>
@required

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath atPoint:(CGPoint)point;

@optional

- (void)collectionView:(UICollectionView *)collectionView willBeginDragOfIndex:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView willEndDragOfIndex:(NSIndexPath *)indexPath;

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView alterTranslation:(CGPoint *)translation;
- (CGAffineTransform)collectionView:(UICollectionView *)collectionView transformForDraggingItemAtIndexPath:(NSIndexPath *)indexPath duration:(NSTimeInterval *)duration;
- (BOOL)collectionView:(UICollectionView *)collectionView shouldTouchBeginDrag:(UITouch*)touch atIndexPath:(NSIndexPath *)indexPath;

@end
