//
//  Copyright (c) 2013 Luke Scott
//  https://github.com/lukescott/DraggableCollectionView
//  Distributed under MIT license
//

#import "ViewController.h"
#import "Cell.h"

#define SECTION_COUNT 5
#define ITEM_COUNT 10

@interface ViewController ()
{
    NSMutableArray *topSections;
    NSMutableArray *bottomSections;
}
@property (nonatomic, weak) IBOutlet UICollectionView *targetCollectionView;

@property (nonatomic, strong) NSIndexPath *externalHoverIndexPath;
@property (nonatomic, strong) id externalHoverObject;

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
    cell.hidden = [[data objectAtIndex:indexPath.item] isEqual:_externalHoverObject];
    return cell;
}

- (BOOL)collectionView:(LSCollectionViewHelper *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath
{
// Prevent item from being moved to index 0
    if (toIndexPath.item == 0) {
        return NO;
    }
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
    id objectToMove = [data1 objectAtIndex:fromIndexPath.item];
    
    [data1 removeObjectAtIndex:fromIndexPath.item];
    [data2 insertObject:objectToMove atIndex:toIndexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView willBeginDragOfIndex:(NSIndexPath *)indexPath
{
    NSLog(@"willBeginDragOfIndex:%@", indexPath);
}

- (void)collectionView:(UICollectionView *)collectionView willEndDragOfIndex:(NSIndexPath *)indexPath
{
    NSLog(@"willEndDragOfIndex:%@", indexPath);
}

- (UIView *) viewForDraggingFromCollectionView:(UICollectionView *)collectionView
{
    return self.view;
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
- (BOOL) collectionView:(UICollectionView *)collectionView canDropInTarget:(UIView *)targetView atPoint:(CGPoint)dropPoint fromIndexPath:(NSIndexPath *)indexPath
{
    UICollectionView *targetCV = (UICollectionView *)targetView;
    return ([targetCV indexPathForItemClosestToPoint:dropPoint mustBeValidMoveTarget:YES] != nil);
}

- (void)collectionView:(UICollectionView *)collectionView didDropInTarget:(UIView *)targetView atPoint:(CGPoint)dropPoint fromIndexPath:(NSIndexPath *)indexPath
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
    // Insert
    UICollectionView *targetCV = (UICollectionView *)targetView;
    NSIndexPath *targetIndexPath = [targetCV indexPathForItemClosestToPoint:dropPoint mustBeValidMoveTarget:YES];
    if (!targetIndexPath) {
        NSLog(@"No Valid indexPaths Found! Can't move object over. BAILING");
        return;
    }
    NSMutableArray *targetArray = [targetSections objectAtIndex:targetIndexPath.section];
    [targetArray insertObject:toMove atIndex:targetIndexPath.item];
    [targetCV insertItemsAtIndexPaths:@[targetIndexPath]];
    // Remove
    [data1 removeObjectAtIndex:indexPath.item];
    [collectionView deleteItemsAtIndexPaths:@[indexPath]];
}

- (void)collectionView:(UICollectionView *)collectionView dragEnteredTarget:(UIView *)targetView atPoint:(CGPoint)didEnterPoint fromIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"did enter target [%@] at point:[%@,%@]", targetView, @(didEnterPoint.x), @(didEnterPoint.y));
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
    self.externalHoverObject = ((NSArray *)sourceSections[indexPath.section])[indexPath.item];
    UICollectionView *targetCV = (UICollectionView *)targetView;
    self.externalHoverIndexPath = [targetCV indexPathForItemClosestToPoint:didEnterPoint mustBeValidMoveTarget:YES];
    if (_externalHoverIndexPath) {
        NSMutableArray *targetArray = [targetSections objectAtIndex:_externalHoverIndexPath.section];
        [targetArray insertObject:_externalHoverObject atIndex:_externalHoverIndexPath.item];
        [targetCV insertItemsAtIndexPaths:@[_externalHoverIndexPath]];
    }
    else {
        NSLog(@"No Valid indexPaths Found! Can't add to dataSource");
    }
}

- (void) collectionView:(UICollectionView *)collectionView dragUpdateInTarget:(UIView *)targetView atPoint:(CGPoint)didDragInPoint fromIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"did drag in target [%@] at point:[%@,%@]", targetView, @(didDragInPoint.x), @(didDragInPoint.y));
    UICollectionView *targetCV = (UICollectionView *)targetView;
    NSIndexPath *nextIndexPath = [targetCV indexPathForItemClosestToPoint:didDragInPoint mustBeValidMoveTarget:YES];
    if (!nextIndexPath) {
        NSLog(@"No Valid indexPaths Found! Can't add to dataSource");
        return;
    }
    NSMutableArray *targetSection = nil;
    if ([collectionView isEqual:_collectionView]) {
        targetSection = bottomSections[nextIndexPath.section];
    }
    else if ([collectionView isEqual:_targetCollectionView]) {
        targetSection = topSections[nextIndexPath.section];
    }
    // Need to handle trying to add ourselves to the end when we are already at the end of the section
    if (nextIndexPath.item >= targetSection.count && [targetSection containsObject:_externalHoverObject]) {
        nextIndexPath = [NSIndexPath indexPathForItem:targetSection.count-1 inSection:nextIndexPath.section];
    }
    if (![self collectionView:targetCV canMoveItemAtIndexPath:_externalHoverIndexPath toIndexPath:nextIndexPath]) {
        return;
    }
    if (![nextIndexPath isEqual:_externalHoverIndexPath]) {
        if (!_externalHoverIndexPath) { // We didn't have a valid target initially, but now we do some how.
            [targetSection insertObject:_externalHoverObject atIndex:nextIndexPath.item];
            [targetCV insertItemsAtIndexPaths:@[nextIndexPath]];
        }
        else {
            [self collectionView:targetCV moveItemAtIndexPath:_externalHoverIndexPath toIndexPath:nextIndexPath];
            [targetCV moveItemAtIndexPath:_externalHoverIndexPath toIndexPath:nextIndexPath];
        }
        self.externalHoverIndexPath = nextIndexPath;
    }
}

- (void)collectionView:(UICollectionView *)collectionView dragLeftTarget:(UIView *)targetView fromIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"did leave target [%@]", targetView);
    UICollectionView *targetCV = (UICollectionView *)targetView;
    NSMutableArray *targetSections = nil;
    if ([collectionView isEqual:_collectionView]) {
        targetSections = bottomSections;
    }
    else if ([collectionView isEqual:_targetCollectionView]) {
        targetSections = topSections;
    }
    [targetSections enumerateObjectsUsingBlock:^(NSMutableArray *section, NSUInteger sectionIndex, BOOL *stop) {
        NSInteger index = [section indexOfObject:_externalHoverObject];
        if (index != NSNotFound) {
            [section removeObject:_externalHoverObject];
            [targetCV deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:sectionIndex]]];
            *stop = YES;
        }
    }];
    self.externalHoverIndexPath = nil;
    self.externalHoverObject = nil;
}

@end
