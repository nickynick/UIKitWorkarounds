//
//  UINavigationController+NNStatusBarManagement.h
//  UIKitWorkarounds
//
//  Created by Nick Tymchenko on 05/02/16.
//  Copyright © 2016 Nick Tymchenko. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface UINavigationController (NNStatusBarManagement)

+ (void)nn_setupCorrectStatusBarManagement;

@end


@interface UINavigationBar (NNStatusBarManagement)

@property (nonatomic, assign) UIStatusBarStyle nn_statusBarStyle UI_APPEARANCE_SELECTOR;

@end


NS_ASSUME_NONNULL_END
