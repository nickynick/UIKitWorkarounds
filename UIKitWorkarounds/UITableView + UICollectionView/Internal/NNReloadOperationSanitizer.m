//
//  NNReloadOperationSanitizer.m
//  UIKitWorkarounds
//
//  Created by Nick Tymchenko on 15/01/16.
//  Copyright © 2016 Nick Tymchenko. All rights reserved.
//

#import "NNReloadOperationSanitizer.h"
#import "NNReloadOperations.h"
#import <UIKit/UIKit.h>

@interface NNReloadOperationSanitizer ()

@property (nonatomic, strong) NNReloadOperations *operations;
@property (nonatomic, assign) BOOL customReloadAllowed;

@end


@implementation NNReloadOperationSanitizer

#pragma mark - Public

+ (void)sanitizeOperations:(NNReloadOperations *)operations customReloadAllowed:(BOOL)customReloadAllowed {
    NNReloadOperationSanitizer *sanitizer = [[NNReloadOperationSanitizer alloc] init];
    sanitizer.operations = operations;
    sanitizer.customReloadAllowed = customReloadAllowed;
    
    [sanitizer sanitize];
}

#pragma mark - Private

- (void)sanitize {
    [self sanitizeIndexPathsMovedFromDeletedSectionsOrIntoInsertedSections];
    [self sanitizeReloadedAndMovedIndexPaths];
    [self sanitizeIndexPathsMovedBetweenSections];
}

- (void)sanitizeIndexPathsMovedFromDeletedSectionsOrIntoInsertedSections {
    [self sanitizeIndexPathOperationsWithBlock:^(NSMutableSet<NNIndexPathReloadOperation *> *badOperations, NSMutableSet<NNIndexPathReloadOperation *> *goodOperations) {
        // UIKit would get upset if we attempted to move an item from a section being deleted / into a section being inserted.
        // Therefore, we should break such moves into deletions+insertions.
        
        NSIndexSet *deletedSections = [self deletedSections];
        NSIndexSet *insertedSections = [self insertedSections];
        
        [self.operations enumerateIndexPathOperationsOfType:NNReloadOperationTypeMove withBlock:^(NNIndexPathReloadOperation *operation, BOOL *stop) {
            if ([deletedSections containsIndex:operation.before.section]) {
                [badOperations addObject:operation];
                
                if (![insertedSections containsIndex:operation.after.section]) {
                    [goodOperations addObject:[[NNIndexPathReloadOperation alloc] initWithType:NNReloadOperationTypeInsert
                                                                                       context:operation.context
                                                                                        before:nil
                                                                                         after:operation.after]];
                }
            } else if ([insertedSections containsIndex:operation.after.section]) {
                [badOperations addObject:operation];
                
                [goodOperations addObject:[[NNIndexPathReloadOperation alloc] initWithType:NNReloadOperationTypeDelete
                                                                                   context:operation.context
                                                                                    before:operation.before
                                                                                     after:nil]];
            }
        }];
    }];
}

- (void)sanitizeReloadedAndMovedIndexPaths {
    NSSet<NSIndexPath *> *movedFromIndexPaths = [self movedFromIndexPaths];

    if (movedFromIndexPaths.count == 0) {
        // Phew, there are no moves! Bail out.
        return;
    }
    
    NSSet<NSIndexPath *> *reloadedIndexPaths = [self reloadedIndexPaths];
    
    [self sanitizeIndexPathOperationsWithBlock:^(NSMutableSet<NNIndexPathReloadOperation *> *badOperations, NSMutableSet<NNIndexPathReloadOperation *> *goodOperations) {
        [self.operations enumerateIndexPathOperationsOfType:NNReloadOperationTypeMove withBlock:^(NNIndexPathReloadOperation *operation, BOOL *stop) {
            if ([reloadedIndexPaths containsObject:operation.before]) {
                if (self.customReloadAllowed) {
                    [goodOperations addObject:[[NNIndexPathReloadOperation alloc] initWithType:NNReloadOperationTypeCustomReload
                                                                                       context:operation.context
                                                                                        before:operation.before
                                                                                         after:operation.after]];
                } else {
                    [badOperations addObject:operation];
                }
            }
        }];
        
        [self.operations enumerateIndexPathOperationsOfType:NNReloadOperationTypeReload withBlock:^(NNIndexPathReloadOperation *operation, BOOL *stop) {
            [badOperations addObject:operation];
            
            if (![movedFromIndexPaths containsObject:operation.before] || !self.customReloadAllowed) {
                [goodOperations addObject:[[NNIndexPathReloadOperation alloc] initWithType:NNReloadOperationTypeDelete
                                                                                   context:operation.context
                                                                                    before:operation.before
                                                                                     after:nil]];
                
                [goodOperations addObject:[[NNIndexPathReloadOperation alloc] initWithType:NNReloadOperationTypeInsert
                                                                                   context:operation.context
                                                                                    before:nil
                                                                                     after:operation.after]];
            }
        }];
    }];
}

- (void)sanitizeIndexPathsMovedBetweenSections {
    [self sanitizeIndexPathOperationsWithBlock:^(NSMutableSet<NNIndexPathReloadOperation *> *badOperations, NSMutableSet<NNIndexPathReloadOperation *> *goodOperations) {
        [self.operations enumerateIndexPathOperationsOfType:NNReloadOperationTypeMove withBlock:^(NNIndexPathReloadOperation *operation, BOOL *stop) {
            // TODO
            
//            // Move animations between different sections will crash if the destination section index doesn't match its initial one (thanks UIKit!)
//            NSUInteger sourceSectionIndex = [change.before indexAtPosition:0];
//            NSUInteger destinationSectionIndex = [change.after indexAtPosition:0];
//            NSUInteger oldDestinationSectionIndex = [tracker oldIndexForSection:destinationSectionIndex];
//            
//            if (sourceSectionIndex != oldDestinationSectionIndex && destinationSectionIndex != oldDestinationSectionIndex) {
            if ((NO)) {
                [badOperations addObject:operation];
                
                [goodOperations addObject:[[NNIndexPathReloadOperation alloc] initWithType:NNReloadOperationTypeDelete
                                                                                   context:operation.context
                                                                                    before:operation.before
                                                                                     after:nil]];
                
                [goodOperations addObject:[[NNIndexPathReloadOperation alloc] initWithType:NNReloadOperationTypeInsert
                                                                                   context:operation.context
                                                                                    before:nil
                                                                                     after:operation.after]];
            }
        }];
    }];
}

#pragma mark - Helpers

- (void)sanitizeIndexPathOperationsWithBlock:(void (^)(NSMutableSet<NNIndexPathReloadOperation *> *badOperations,
                                                       NSMutableSet<NNIndexPathReloadOperation *> *goodOperations))block
{
    NSMutableSet<NNIndexPathReloadOperation *> *badOperations = [NSMutableSet set];
    NSMutableSet<NNIndexPathReloadOperation *> *goodOperations = [NSMutableSet set];
    
    block(badOperations, goodOperations);
    
    [self.operations.indexPathOperations minusSet:badOperations];
    [self.operations.indexPathOperations unionSet:goodOperations];
}

- (NSIndexSet *)deletedSections {
    NSMutableIndexSet *sections = [[NSMutableIndexSet alloc] init];
    [self.operations enumerateSectionOperationsOfType:NNReloadOperationTypeDelete withBlock:^(NNSectionReloadOperation *operation, BOOL *stop) {
        [sections addIndex:operation.before];
    }];
    return sections;
}

- (NSIndexSet *)insertedSections {
    NSMutableIndexSet *sections = [[NSMutableIndexSet alloc] init];
    [self.operations enumerateSectionOperationsOfType:NNReloadOperationTypeInsert withBlock:^(NNSectionReloadOperation *operation, BOOL *stop) {
        [sections addIndex:operation.after];
    }];
    return sections;
}

- (NSSet<NSIndexPath *> *)reloadedIndexPaths {
    NSMutableSet<NSIndexPath *> *indexPaths = [NSMutableSet set];
    [self.operations enumerateIndexPathOperationsOfType:NNReloadOperationTypeReload withBlock:^(NNIndexPathReloadOperation *operation, BOOL *stop) {
        [indexPaths addObject:operation.before];
    }];
    return indexPaths;
}

- (NSSet<NSIndexPath *> *)movedFromIndexPaths {
    NSMutableSet<NSIndexPath *> *indexPaths = [NSMutableSet set];
    [self.operations enumerateIndexPathOperationsOfType:NNReloadOperationTypeMove withBlock:^(NNIndexPathReloadOperation *operation, BOOL *stop) {
        [indexPaths addObject:operation.before];
    }];
    return indexPaths;
}

@end
