//
//  NNReloadMapper.m
//  UIKitWorkarounds
//
//  Created by Nick Tymchenko on 26/01/16.
//  Copyright © 2016 Nick Tymchenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NNReloadMapper.h"
#import "NNReloadOperations.h"
#import "NNIndexMapping.h"

@interface NNReloadMapper ()

@property (nonatomic, strong, readonly) NNReloadOperations *operations;

@property (nonatomic, strong, readonly) NNIndexMapping *sectionMapping;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, NNIndexMapping *> *indexMappingsPerSectionBefore;

@end


@implementation NNReloadMapper

#pragma mark - Init

- (instancetype)initWithReloadOperations:(NNReloadOperations *)operations {
    self = [super init];
    if (!self) return nil;
    
    _operations = operations;
    
    [self calculateMappings];
    
    return self;
}

#pragma mark - Calculations

- (void)calculateMappings {
    [self calculateSectionMapping];
    [self calculateIndexMappings];
}

- (void)calculateSectionMapping {
    NSMutableIndexSet *deleted = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *inserted = [NSMutableIndexSet indexSet];
    
    for (NNSectionReloadOperation *operation in self.operations.sectionOperations) {
        if (operation.type == NNReloadOperationTypeDelete || operation.type == NNReloadOperationTypeMove) {
            [deleted addIndex:operation.before];
        }
        
        if (operation.type == NNReloadOperationTypeInsert || operation.type == NNReloadOperationTypeMove) {
            [inserted addIndex:operation.after];
        }
    }
    
    _sectionMapping = [[NNIndexMapping alloc] initWithDeletedIndexes:deleted insertedIndexes:inserted];
}

- (void)calculateIndexMappings {
    _indexMappingsPerSectionBefore = [NSMutableDictionary dictionary];
    
    NSMutableDictionary<NSNumber *, NSMutableIndexSet *> *deletedIndexesPerSectionBefore = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSNumber *, NSMutableIndexSet *> *insertedIndexesPerSectionBefore = [NSMutableDictionary dictionary];
    NSMutableIndexSet *affectedSectionsBefore = [NSMutableIndexSet indexSet];
    
    for (NNIndexPathReloadOperation *operation in self.operations.indexPathOperations) {
        if (operation.type == NNReloadOperationTypeDelete || operation.type == NNReloadOperationTypeMove) {
            NSInteger sectionBefore = operation.before.section;
            
            NSMutableIndexSet *deletedIndexes = deletedIndexesPerSectionBefore[@(sectionBefore)];
            if (!deletedIndexes) {
                deletedIndexes = [NSMutableIndexSet indexSet];
                deletedIndexesPerSectionBefore[@(sectionBefore)] = deletedIndexes;
                
                [affectedSectionsBefore addIndex:sectionBefore];
            }
            
            [deletedIndexes addIndex:operation.before.row];
        }
        
        if (operation.type == NNReloadOperationTypeInsert || operation.type == NNReloadOperationTypeMove) {
            NSInteger sectionBefore = [_sectionMapping indexAfterToIndexBefore:operation.after.section];
            
            NSMutableIndexSet *insertedIndexes = insertedIndexesPerSectionBefore[@(sectionBefore)];
            if (!insertedIndexes) {
                insertedIndexes = [NSMutableIndexSet indexSet];
                insertedIndexesPerSectionBefore[@(sectionBefore)] = insertedIndexes;
                
                [affectedSectionsBefore addIndex:sectionBefore];
            }
            
            [insertedIndexes addIndex:operation.after.row];
        }
    }
    
    [affectedSectionsBefore enumerateIndexesUsingBlock:^(NSUInteger sectionBefore, BOOL *stop) {
        NSIndexSet *deletedIndexes = deletedIndexesPerSectionBefore[@(sectionBefore)] ?: [NSIndexSet indexSet];
        NSIndexSet *insertedIndexes = insertedIndexesPerSectionBefore[@(sectionBefore)] ?: [NSIndexSet indexSet];
        
        _indexMappingsPerSectionBefore[@(sectionBefore)] = [[NNIndexMapping alloc] initWithDeletedIndexes:deletedIndexes
                                                                                          insertedIndexes:insertedIndexes];
    }];
}

#pragma mark - Public

- (NSUInteger)sectionBeforeToSectionAfter:(NSUInteger)sectionBefore {
    return [self.sectionMapping indexBeforeToIndexAfter:sectionBefore];
}

- (NSUInteger)sectionAfterToSectionBefore:(NSUInteger)sectionAfter {
    return [self.sectionMapping indexAfterToIndexBefore:sectionAfter];
}

- (NSIndexPath *)indexPathBeforeToIndexPathAfter:(NSIndexPath *)indexPathBefore {
    NSUInteger sectionAfter = [self sectionBeforeToSectionAfter:indexPathBefore.section];
    
    NNIndexMapping *indexMapping = self.indexMappingsPerSectionBefore[@(indexPathBefore.section)];
    NSUInteger indexAfter = indexMapping ? [indexMapping indexBeforeToIndexAfter:indexPathBefore.row] : indexPathBefore.row;
    
    return [NSIndexPath indexPathForRow:indexAfter inSection:sectionAfter];
}

- (NSIndexPath *)indexPathAfterToIndexPathBefore:(NSIndexPath *)indexPathAfter {
    NSUInteger sectionBefore = [self sectionAfterToSectionBefore:indexPathAfter.section];
    
    NNIndexMapping *indexMapping = self.indexMappingsPerSectionBefore[@(sectionBefore)];
    NSUInteger indexBefore = indexMapping ? [indexMapping indexAfterToIndexBefore:indexPathAfter.row] : indexPathAfter.row;
    
    return [NSIndexPath indexPathForRow:indexBefore inSection:sectionBefore];
}

@end
