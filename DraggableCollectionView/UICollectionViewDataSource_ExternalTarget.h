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
- (NSArray *)externalTargets;
- (void)collectionView:(UICollectionView *)collectionView didHitTarget:(UIView *)targetView fromIndexPath:(NSIndexPath *)indexPath;

@optional
- (void)collectionView:(UICollectionView *)collectionView enterTarget:(UIView *)didEnterTargetView;
- (void)collectionView:(UICollectionView *)collectionView leaveTarget:(UIView *)didLeaveTargetView;

@end
