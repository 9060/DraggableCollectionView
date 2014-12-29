//
//  Copyright (c) 2013 Luke Scott
//  https://github.com/lukescott/DraggableCollectionView
//  Distributed under MIT license
//

#import <UIKit/UIKit.h>
#import "UICollectionView+Draggable.h"

@interface ViewController : UIViewController < UICollectionViewDataSource_DraggableWithExternalTarget, UICollectionViewDelegate >

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end
