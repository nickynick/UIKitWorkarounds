//
//  DemoTableViewController.m
//  Demo
//
//  Created by Nick Tymchenko on 28/01/16.
//  Copyright © 2016 Nick Tymchenko. All rights reserved.
//

#import "DemoTableViewController.h"
#import <UIKitWorkarounds/UIKitWorkarounds.h>

static NSString * const kCellIdentifier = @"cell";


@interface DemoTableViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readonly) UITableView *tableView;

@property (nonatomic, strong, readonly) NSMutableArray<NSMutableArray<NSString *> *> *items;
@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *sectionTitles;

@end


@implementation DemoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    [self.view addSubview:_tableView];
    
    UIBarButtonItem *actionBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Pew"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(doSomethingWithData)];
    self.navigationItem.rightBarButtonItem = actionBarButton;
    
    [self setupData];
}

- (void)setupData {
    _items = [NSMutableArray array];
    _sectionTitles = [NSMutableArray array];
    
    [self addSectionWithItems:@[ @"a1", @"a2", @"a3" ] title:@"A" atIndex:0];
    [self addSectionWithItems:@[ @"b1", @"b2", @"b3" ] title:@"B" atIndex:1];
    [self addSectionWithItems:@[ @"c1", @"c2", @"c3" ] title:@"C" atIndex:2];
}

- (void)addSectionWithItems:(NSArray<NSString *> *)items title:(NSString *)title atIndex:(NSUInteger)index {
    [self.items insertObject:[items mutableCopy] atIndex:index];
    [self.sectionTitles insertObject:title atIndex:index];
}

- (void)doSomethingWithData {
    self.items[0][1] = @"a2 (updated)";
    
    NSString *item = self.items[0][0];
    [self.items[0] removeObjectAtIndex:0];
    [self.items[2] insertObject:item atIndex:0];
    
    [self addSectionWithItems:@[ @"derp", @"foo" ] title:@"🐓" atIndex:0];
    
    NNTableViewReloader *reloader = [[NNTableViewReloader alloc] initWithTableView:self.tableView];
    
    [reloader performUpdates:^{
        [reloader insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        
        [reloader reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:1 inSection:0] ] withRowAnimation:UITableViewRowAnimationFade];
        
        [reloader moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                         toIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]];
    } completion:nil];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = self.items[indexPath.section][indexPath.row];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionTitles[section];
}

@end
