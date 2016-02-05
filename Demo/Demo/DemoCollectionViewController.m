//
//  DemoCollectionViewController.m
//  Demo
//
//  Created by Nick Tymchenko on 05/02/16.
//  Copyright © 2016 Nick Tymchenko. All rights reserved.
//

#import "DemoCollectionViewController.h"
#import <UIKitWorkarounds/UIKitWorkarounds.h>

static NSString * const kCellIdentifier = @"cell";


@interface DemoCollectionViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property (nonatomic, strong, readonly) UICollectionView *collectionView;

@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *items;

@end


@implementation DemoCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(100, 100);
    
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kCellIdentifier];
    [self.view addSubview:_collectionView];
    
    UIBarButtonItem *actionBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Pew"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(pew)];
    self.navigationItem.rightBarButtonItem = actionBarButton;
    
    [self setupData];
}

- (void)setupData {
    _items = [NSMutableArray array];
}

- (void)doSomethingWithData {
    const NSInteger numberOfItems = 100;
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSInteger i = 0; i < numberOfItems; ++i) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
    }
    
    if (self.items.count == 0) {
        for (NSInteger i = 0; i < numberOfItems; ++i) {
            [self.items addObject:[@(i) stringValue]];
        }
        
//        [self.collectionView performBatchUpdates:^{
//            [self.collectionView insertItemsAtIndexPaths:indexPaths];
//        } completion:nil];
        
        [self.collectionView reloadData];
        [self.collectionView performBatchUpdates:nil completion:nil];
    } else {
        [self.items removeAllObjects];
        
        [self.collectionView performBatchUpdates:^{
            [self.collectionView deleteItemsAtIndexPaths:indexPaths];
        } completion:nil];
    }
}

- (void)pew {
    [self doSomethingWithData];
    [self doSomethingWithData];
}

#pragma mark - UICollectionViewDelegate & UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor lightGrayColor];
    return cell;
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
//    CGFloat width = CGRectGetWidth(self.view.bounds);
//    return CGSizeMake(width, width);
//}

@end
