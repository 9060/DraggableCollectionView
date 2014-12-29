//
//  Copyright (c) 2013 Luke Scott
//  https://github.com/lukescott/DraggableCollectionView
//  Distributed under MIT license
//

#import "ViewController.h"
#import "Cell.h"

#define SECTION_COUNT 2
#define ITEM_COUNT 5

@interface ViewController ()
{
    NSMutableArray *topSections;
    NSMutableArray *bottomSections;
}
@property (nonatomic, weak) IBOutlet UICollectionView *targetCollectionView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    topSections = [[NSMutableArray alloc] initWithCapacity:ITEM_COUNT];
    bottomSections = [[NSMutableArray alloc] initWithCapacity:ITEM_COUNT];
    for(int s = 0; s < SECTION_COUNT; s++) {
        NSMutableArray *topData = [[NSMutableArray alloc] initWithCapacity:ITEM_COUNT];
        NSMutableArray *bottomData = [[NSMutableArray alloc] initWithCapacity:ITEM_COUNT];
        for(int i = 0; i < ITEM_COUNT; i++) {
            [topData addObject:[NSString stringWithFormat:@"top-%c %@", 65+s, @(i)]];
            [bottomData addObject:[NSString stringWithFormat:@"bottom-%c %@", 65+s, @(i)]];
        }
        [topSections addObject:topData];
        [bottomSections addObject:bottomData];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if ([collectionView isEqual:_collectionView]) {
        return topSections.count;
    }
    else if ([collectionView isEqual:_targetCollectionView]) {
        return bottomSections.count;
    }
    return 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([collectionView isEqual:_collectionView]) {
        return [[topSections objectAtIndex:section] count];
    }
    else if ([collectionView isEqual:_targetCollectionView]) {
        return [[bottomSections objectAtIndex:section] count];
    }

    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Cell *cell = (Cell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    NSMutableArray *data = nil;
    if ([collectionView isEqual:_collectionView]) {
        data = [topSections objectAtIndex:indexPath.section];
    }
    else if ([collectionView isEqual:_targetCollectionView]) {
        data = [bottomSections objectAtIndex:indexPath.section];
    }
   
    cell.label.text = [data objectAtIndex:indexPath.item];
    
    return cell;
}

- (BOOL)collectionView:(LSCollectionViewHelper *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath
{
// Prevent item from being moved to index 0
//    if (toIndexPath.item == 0) {
//        return NO;
//    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *sections = nil;
    if ([collectionView isEqual:_collectionView]) {
        sections = topSections;
    }
    else if ([collectionView isEqual:_targetCollectionView]) {
        sections = bottomSections;
    }

    NSMutableArray *data1 = [sections objectAtIndex:fromIndexPath.section];
    NSMutableArray *data2 = [sections objectAtIndex:toIndexPath.section];
    NSString *index = [data1 objectAtIndex:fromIndexPath.item];
    
    [data1 removeObjectAtIndex:fromIndexPath.item];
    [data2 insertObject:index atIndex:toIndexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView willBeginDragOfIndex:(NSIndexPath *)indexPath
{
    NSLog(@"willBeginDragOfIndex:%@", indexPath);
}

- (void)collectionView:(UICollectionView *)collectionView willEndDragOfIndex:(NSIndexPath *)indexPath
{
    NSLog(@"willEndDragOfIndex:%@", indexPath);
}

#pragma mark - UICollectionViewDataSource_ExternalTarget
- (NSArray *)externalTargetsForCollectionView:(UICollectionView *)collectionView
{
    if ([collectionView isEqual:_collectionView]) {
        return @[self.targetCollectionView];
    }
    else if ([collectionView isEqual:_targetCollectionView]) {
        return @[self.collectionView];
    }

    return @[self.targetCollectionView];
}

// Dropping Externally
- (void)collectionView:(UICollectionView *)collectionView didHitTarget:(UIView *)targetView atPoint:(CGPoint)dropPoint fromIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *sourceSections = nil;
    NSMutableArray *targetSections = nil;
    if ([collectionView isEqual:_collectionView]) {
        sourceSections = topSections;
        targetSections = bottomSections;
    }
    else if ([collectionView isEqual:_targetCollectionView]) {
        sourceSections = bottomSections;
        targetSections = topSections;
    }

    NSLog(@"Dropped in Target:[%@] at point:[%@,%@]", targetView, @(dropPoint.x), @(dropPoint.y));
    NSLog(@"%@ hit me! Removing item ...", indexPath);
    
    NSMutableArray *data1 = [sourceSections objectAtIndex:indexPath.section];
    id toMove = [data1 objectAtIndex:indexPath.item];
    // Remove
    [data1 removeObjectAtIndex:indexPath.item];
    [collectionView deleteItemsAtIndexPaths:@[ indexPath ]];
    // Insert
    UICollectionView *targetCV = (UICollectionView *)targetView;
    NSIndexPath *targetIndexPath = [targetCV indexPathForItemClosestToPoint:dropPoint];
    NSMutableArray *targetArray = [targetSections objectAtIndex:targetIndexPath.section];
    [targetArray insertObject:toMove atIndex:targetIndexPath.item];
    [targetCV insertItemsAtIndexPaths:@[targetIndexPath]];
}

- (void)collectionView:(UICollectionView *)collectionView enterTarget:(UIView *)didEnterTargetView atPoint:(CGPoint)didEnterPoint fromIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"did enter target [%@] at point:[%@,%@]", didEnterTargetView, @(didEnterPoint.x), @(didEnterPoint.y));
}

- (void) collectionView:(UICollectionView *)collectionView dragInTarget:(UIView *)didDragInTargetView atPoint:(CGPoint)didDragInPoint fromIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"did drag in target [%@] at point:[%@,%@]", didDragInTargetView, @(didDragInPoint.x), @(didDragInPoint.y));
}

- (void)collectionView:(UICollectionView *)collectionView leaveTarget:(UIView *)didLeaveTargetView fromIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"did leave target [%@]", didLeaveTargetView);
}

@end
