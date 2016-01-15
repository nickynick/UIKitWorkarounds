//
//  NNReloadOperationSanitizer.h
//  UIKitWorkarounds
//
//  Created by Nick Tymchenko on 15/01/16.
//  Copyright © 2016 Nick Tymchenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NNReloadOperations;


@interface NNReloadOperationSanitizer : NSObject

+ (void)sanitizeOperations:(NNReloadOperations *)operations customReloadAllowed:(BOOL)customReloadAllowed;

@end
