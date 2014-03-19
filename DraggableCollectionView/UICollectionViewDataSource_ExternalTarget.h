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
- (UIView *)externalTargetView;

- (void)collectionView:(UICollectionView *)collectionView didHitTarget:(BOOL)didHit;

@optional
- (void)collectionView:(UICollectionView *)collectionView enterTarget:(BOOL)didEnter;
- (void)collectionView:(UICollectionView *)collectionView leaveTarget:(BOOL)didLeave;

@end
