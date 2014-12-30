//
//  Copyright (c) 2013 Luke Scott
//  https://github.com/lukescott/DraggableCollectionView
//  Distributed under MIT license
//

#import "ViewController.h"
#import "Cell.h"
#import "DraggableCircleLayout.h"

@interface ViewController ()
{
    NSMutableArray *topData;
    NSMutableArray *bottomData;
}

@property (nonatomic, weak) IBOutlet UICollectionView *bottomCollectionView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    topData = [NSMutableArray arrayWithCapacity:20];
    bottomData = [NSMutableArray arrayWithCapacity:20];
    for(int i = 0; i < 20; i++) {
        [topData addObject:[NSString stringWithFormat:@"top-%@",@(i)]];
        [bottomData addObject:[NSString stringWithFormat:@"bottom-%@",@(i)]];
    }
    
    self.collectionView.collectionViewLayout = [[DraggableCircleLayout alloc] init];
}

- (NSMutableArray *)dataForCollectionView:(UICollectionView *)collectionView
{
    if ([collectionView isEqual:_collectionView]) {
        return topData;
    }
    else if ([collectionView isEqual:_bottomCollectionView]) {
        return bottomData;
    }
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self dataForCollectionView:collectionView].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Cell *cell = (Cell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    NSString *index = [[self dataForCollectionView:collectionView] objectAtIndex:indexPath.item];
    cell.label.text = index;
    
    return cell;
}

- (BOOL)collectionView:(LSCollectionViewHelper *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *data = [self dataForCollectionView:collectionView];
    NSNumber *index = [data objectAtIndex:fromIndexPath.item];
    [data removeObjectAtIndex:fromIndexPath.item];
    [data insertObject:index atIndex:toIndexPath.item];
}

@end
