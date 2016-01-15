//
//  NNReloadOperations.m
//  UIKitWorkarounds
//
//  Created by Nick Tymchenko on 15/01/16.
//  Copyright © 2016 Nick Tymchenko. All rights reserved.
//

#import "NNReloadOperations.h"

@implementation NNReloadOperation

- (instancetype)initWithType:(NNReloadOperationType)type context:(id)context {
    self = [super init];
    if (!self) return nil;
    
    _type = type;
    _context = context;
    
    return self;
}

@end


@implementation NNIndexPathReloadOperation

- (instancetype)initWithType:(NNReloadOperationType)type
                     context:(nullable id)context
                      before:(nullable NSIndexPath *)before
                       after:(nullable NSIndexPath *)after
{
    self = [super initWithType:type context:context];
    if (!self) return nil;
    
    _before = before;
    _after = after;
    
    return self;
}

@end


@implementation NNSectionReloadOperation

- (instancetype)initWithType:(NNReloadOperationType)type
                     context:(nullable id)context
                      before:(NSUInteger)before
                       after:(NSUInteger)after
{
    NSAssert(type != NNReloadOperationTypeCustomReload, @"Custom reload is not applicable to sections.");
    
    self = [super initWithType:type context:context];
    if (!self) return nil;
    
    _before = before;
    _after = after;
    
    return self;
}

@end


@implementation NNReloadOperations

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    _indexPathOperations = [NSMutableSet set];
    _sectionOperations = [NSMutableSet set];
    
    return self;
}

- (void)enumerateIndexPathOperationsOfType:(NNReloadOperationType)type withBlock:(void (^)(NNIndexPathReloadOperation *operation, BOOL *stop))block {
    BOOL stop = NO;
    
    for (NNIndexPathReloadOperation *operation in self.indexPathOperations) {
        if (operation.type == type) {
            block(operation, &stop);
            
            if (stop) {
                break;
            }
        }
    }
}

- (void)enumerateSectionOperationsOfType:(NNReloadOperationType)type withBlock:(void (^)(NNSectionReloadOperation *operation, BOOL *stop))block {
    BOOL stop = NO;
    
    for (NNSectionReloadOperation *operation in self.sectionOperations) {
        if (operation.type == type) {
            block(operation, &stop);
            
            if (stop) {
                break;
            }
        }
    }
}

@end