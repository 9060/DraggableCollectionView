//
//  UICollectionViewDatasource_ExternalTarget.h
//  FlowLayoutDemo
//
//  Created by Armando Di Cianno on 3/18/14.
//  Copyright (c) 2014 Luke Scott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UICollectionViewDataSource_Draggable.h"

@protocol UICollectionViewDataSource_DraggableWithExternalTarget <UICollectionViewDataSource_Draggable>

@required
/*
 *  Array of targetViews that the cell can be dropped onto. Each must be UIView or subclass.
 */
- (NSArray *)externalTargetsForCollectionView:(UICollectionView *)collectionView;
/*
 *  Called when the user drops a cell over a targetView. It is up to the receiver to add/remove both the sender and the receiver.
 *  If a valid CGPoint is returned, the mockCell will animate its centre to that location. Point is expected to be in targetView's coordinates,
 *  and will be translated into coordinates for view returned by viewForDraggingFromCollectionView: if implemented.
 */
- (CGPoint)collectionView:(UICollectionView *)collectionView didDropInTarget:(UIView *)targetView atPoint:(CGPoint)dropPoint fromIndexPath:(NSIndexPath *)indexPath;

@optional

/*
 * Optionally called when user tries to drop a cell on an external targetView.
 *  If receiver returns NO then cell animates return to starting position.
 *  If receiver returns YES then collectionView:didDropInTarget:atPoint:fromIndexPath: will be called
 */
- (BOOL)collectionView:(UICollectionView *)collectionView canDropInTarget:(UIView *)targetView atPoint:(CGPoint)dropPoint fromIndexPath:(NSIndexPath *)indexPath;
/*
 * Optional view to inject the mockCell (which you drag with your finger) into. This allows the cell to be dragged outside
 *  of the collectionView's bounds.
 */
- (UIView *)viewForDraggingFromCollectionView:(UICollectionView *)collectionView;
/*
 *  Triggered when a cell is dragged over a new targetView.
 */
- (void)collectionView:(UICollectionView *)collectionView dragEnteredTarget:(UIView *)targetView atPoint:(CGPoint)didEnterPoint fromIndexPath:(NSIndexPath *)indexPath;
/*
 *  Triggered as a cell continues to be dragged over a targetView.
 */
- (void)collectionView:(UICollectionView *)collectionView dragUpdateInTarget:(UIView *)targetView atPoint:(CGPoint)didDragInPoint fromIndexPath:(NSIndexPath *)indexPath;
/*
 *  Triggered when a cell is dragged out of a targetView or when the cell is dropped onto the targetView
 */
- (void)collectionView:(UICollectionView *)collectionView dragLeftTarget:(UIView *)targetView fromIndexPath:(NSIndexPath *)indexPath;

@end
