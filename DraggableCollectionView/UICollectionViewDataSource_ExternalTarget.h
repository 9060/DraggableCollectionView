//
//  UICollectionViewDatasource_ExternalTarget.h
//  FlowLayoutDemo
//
//  Created by Armando Di Cianno on 3/18/14.
//  Copyright (c) 2014 Luke Scott. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UICollectionViewDataSource_ExternalTarget <UICollectionViewDataSource>

@required
- (NSArray *)externalTargetsForCollectionView:(UICollectionView *)collectionView;
- (void)collectionView:(UICollectionView *)collectionView didHitTarget:(UIView *)targetView atPoint:(CGPoint)dropPoint fromIndexPath:(NSIndexPath *)indexPath;

@optional
- (void)collectionView:(UICollectionView *)collectionView enterTarget:(UIView *)didEnterTargetView atPoint:(CGPoint)didEnterPoint fromIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView dragInTarget:(UIView *)didDragInTargetView atPoint:(CGPoint)didDragInPoint fromIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView leaveTarget:(UIView *)didLeaveTargetView fromIndexPath:(NSIndexPath *)indexPath;

@end
