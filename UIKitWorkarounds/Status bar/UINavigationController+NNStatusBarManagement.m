//
//  UINavigationController+NNStatusBarManagement.m
//  UIKitWorkarounds
//
//  Created by Nick Tymchenko on 05/02/16.
//  Copyright © 2016 Nick Tymchenko. All rights reserved.
//

#import "UINavigationController+NNStatusBarManagement.h"
#import "NNSwizzlingUtils.h"
#import <objc/runtime.h>

@implementation UINavigationBar (NNStatusBarManagement)

#pragma mark - Public

static const char kStatusBarStyleKey;

- (UIStatusBarStyle)nn_statusBarStyle {
    return [objc_getAssociatedObject(self, &kStatusBarStyleKey) integerValue];
}

- (void)setNn_statusBarStyle:(UIStatusBarStyle)statusBarStyle {
    objc_setAssociatedObject(self, &kStatusBarStyleKey, @(statusBarStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Swizzling

+ (void)nn_statusBarManagement_swizzleMethods {
    // Make .window KVO-compliant, okay?
    
    [NNSwizzlingUtils swizzle:[UINavigationBar class] instanceMethod:@selector(willMoveToWindow:)
                   withMethod:@selector(nn_statusBarManagement_willMoveToWindow:)];
    
    [NNSwizzlingUtils swizzle:[UINavigationBar class] instanceMethod:@selector(didMoveToWindow)
                   withMethod:@selector(nn_statusBarManagement_didMoveToWindow)];
}

- (void)nn_statusBarManagement_willMoveToWindow:(UIWindow *)newWindow {
    [self nn_statusBarManagement_willMoveToWindow:newWindow];
    
    [self willChangeValueForKey:@"window"];
}

- (void)nn_statusBarManagement_didMoveToWindow {
    [self nn_statusBarManagement_didMoveToWindow];
    
    [self didChangeValueForKey:@"window"];
}

@end


@interface UINavigationController ()

@property (nonatomic, assign, getter = nn_isNavigationBarHidden, setter = nn_setNavigationBarHidden:) BOOL nn_navigationBarHidden;

@property (nonatomic, assign, readonly, getter = nn_isRemoteController) BOOL nn_remoteController;

@property (nonatomic, assign, setter = nn_setHasPendingStatusBarAppearanceUpdate:) BOOL nn_hasPendingStatusBarAppearanceUpdate;

@end


@implementation UINavigationController (NNStatusBarManagement)

#pragma mark - Public

+ (void)nn_setupCorrectStatusBarManagement {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self nn_statusBarManagement_swizzleMethods];
        [UINavigationBar nn_statusBarManagement_swizzleMethods];
    });
}

#pragma mark - Swizzling

+ (void)nn_statusBarManagement_swizzleMethods {
    Class aClass = [UINavigationController class];
    
    [NNSwizzlingUtils swizzle:aClass instanceMethod:@selector(viewDidLoad)
                                         withMethod:@selector(nn_statusBarManagement_viewDidLoad)];
    
    [NNSwizzlingUtils swizzle:aClass instanceMethod:@selector(childViewControllerForStatusBarStyle)
                                         withMethod:@selector(nn_statusBarManagement_childViewControllerForStatusBarStyle)];
    
    [NNSwizzlingUtils swizzle:aClass instanceMethod:@selector(childViewControllerForStatusBarHidden)
                                         withMethod:@selector(nn_statusBarManagement_childViewControllerForStatusBarHidden)];
    
    [NNSwizzlingUtils swizzle:aClass instanceMethod:@selector(preferredStatusBarStyle)
                                         withMethod:@selector(nn_statusBarManagement_preferredStatusBarStyle)];
    
    [NNSwizzlingUtils swizzle:aClass instanceMethod:@selector(prefersStatusBarHidden)
                                         withMethod:@selector(nn_statusBarManagement_prefersStatusBarHidden)];
    
    [NNSwizzlingUtils swizzle:aClass instanceMethod:@selector(observeValueForKeyPath:ofObject:change:context:)
                                         withMethod:@selector(nn_statusBarManagement_observeValueForKeyPath:ofObject:change:context:)];
}

- (void)nn_statusBarManagement_viewDidLoad {
    [self nn_statusBarManagement_viewDidLoad];
    
    [self nn_statusBarManagement_setupTracking];
}

- (UIViewController *)nn_statusBarManagement_childViewControllerForStatusBarStyle {
    return [self nn_isInChargeOfStatusBar] ? nil : self.topViewController;
}

- (UIViewController *)nn_statusBarManagement_childViewControllerForStatusBarHidden {
    return [self nn_isInChargeOfStatusBar] ? nil : self.topViewController;
}

- (UIStatusBarStyle)nn_statusBarManagement_preferredStatusBarStyle {
    return self.navigationBar.nn_statusBarStyle;
}

- (BOOL)nn_statusBarManagement_prefersStatusBarHidden {
    if ([self isKindOfClass:[UIImagePickerController class]]) {
        if (((UIImagePickerController *)self).sourceType == UIImagePickerControllerSourceTypeCamera) {
            return YES;
        }
    }
    return NO;
}

- (void)nn_statusBarManagement_observeValueForKeyPath:(NSString *)keyPath
                                             ofObject:(id)object
                                               change:(NSDictionary<NSString *, id> *)change
                                              context:(void *)context {
    if (context == &kNavigationBarKVOContext) {
        self.nn_navigationBarHidden = [self nn_calculateIsNavigationBarHidden];
    } else {
        [self nn_statusBarManagement_observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Status bar logic

static char kNavigationBarKVOContext;

- (void)nn_statusBarManagement_setupTracking {
    // Here be dragons!
    // UIKit properties are not guaranteed to be KVO-compliant, but these actually work fine.
    // Not too likely, but it may break in the future, so we'll have to seek other options.
    
    [self.navigationBar addObserver:self forKeyPath:@"window" options:0 context:&kNavigationBarKVOContext];
    [self.navigationBar addObserver:self forKeyPath:@"layer.bounds" options:0 context:&kNavigationBarKVOContext];
    [self.navigationBar addObserver:self forKeyPath:@"layer.position" options:0 context:&kNavigationBarKVOContext];
    [self.navigationBar addObserver:self forKeyPath:@"alpha" options:0 context:&kNavigationBarKVOContext];
    [self.navigationBar addObserver:self forKeyPath:@"hidden" options:0 context:&kNavigationBarKVOContext];
    
    [self.interactivePopGestureRecognizer addTarget:self action:@selector(nn_statusBarManagement_interactivePopGestureRecognizerChanged:)];
}

- (void)nn_statusBarManagement_interactivePopGestureRecognizerChanged:(UIGestureRecognizer *)recognizer {
    // There is a crazy bug related to interactive pop.
    // Navigation bar may become corrupt if we update status bar at the very start of a gesture, and then user cancels pop.
    // (Yeah, I know.)
    //
    // Why is this important? If you hide/show navigation bar in navigationController:willShowViewController:animated:
    // triggered by interactive pop, this is exactly what happens.
    
    if (recognizer.state != UIGestureRecognizerStateBegan && self.nn_hasPendingStatusBarAppearanceUpdate) {
        self.nn_hasPendingStatusBarAppearanceUpdate = NO;
            
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (BOOL)nn_calculateIsNavigationBarHidden {
    // Why do we have to do all this instead of, e.g. swizzling setNavigationBarHidden:?
    //
    // There are private methods which are also being used for hiding navigation bar, so it's not reliable.
    // One example is UISearchController-related navigation bar animations.
    
    if (!self.navigationBar.window) {
        return YES;
    }
    
    if (self.navigationBar.hidden || self.navigationBar.alpha <= 0.01) {
        return YES;
    }
    
    CGRect intersectionRect = CGRectIntersection(self.view.bounds,
                                                 [self.view convertRect:self.navigationBar.bounds fromView:self.navigationBar]);
    
    BOOL isEmptyIntersection = (CGRectEqualToRect(intersectionRect, CGRectNull) ||
                                intersectionRect.size.width == 0 ||
                                intersectionRect.size.height == 0);
    
    if (isEmptyIntersection) {
        return YES;
    }
    
    return NO;
}

- (BOOL)nn_isInChargeOfStatusBar {
    if (self.nn_remoteController) {
        return YES;
    } else {
        return !self.nn_navigationBarHidden;
    }
}

- (BOOL)nn_checkIfRemoteController {
    // Remote view controllers, being in use since iOS 6, are another tricky case.
    // While they are subclasses of UINavigationController, in fact there's nothing of navigation controller in there.
    // The actual subviews come from the different process, so there's no navigation bar for us to observe.
    
    static NSArray<Class> *remoteControllerClasses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        remoteControllerClasses = [[self class] nn_remoteControllerClasses];
    });
    
    for (Class aClass in remoteControllerClasses) {
        if ([self isKindOfClass:aClass]) {
            return YES;
        }
    }
    
    return NO;
}

+ (NSArray<Class> *)nn_remoteControllerClasses {
    NSArray<NSString *> *classNames = @[ @"MFMailComposeViewController",
                                         @"MFMessageComposeViewController",
                                         @"GKFriendRequestComposeViewController" ];
    
    NSMutableArray<Class> *classes = [NSMutableArray array];
    for (NSString *className in classNames) {
        Class aClass = NSClassFromString(className);
        if (aClass) {
            [classes addObject:aClass];
        }
    }
    
    return [classes copy];
}

#pragma mark - Properties

static const char kNavigationBarHiddenKey;
static const char kRemoteControllerKey;
static const char kHasPendingStatusBarAppearanceUpdateKey;

- (BOOL)nn_isNavigationBarHidden {
    return [objc_getAssociatedObject(self, &kNavigationBarHiddenKey) boolValue];
}

- (void)nn_setNavigationBarHidden:(BOOL)navigationBarHidden {
    if (self.nn_navigationBarHidden == navigationBarHidden) {
        return;
    }
    
    objc_setAssociatedObject(self, &kNavigationBarHiddenKey, @(navigationBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.interactivePopGestureRecognizer.state != UIGestureRecognizerStateBegan) {
        [self setNeedsStatusBarAppearanceUpdate];
    } else {
        self.nn_hasPendingStatusBarAppearanceUpdate = YES;
    }
}

- (BOOL)nn_isRemoteController {
    NSNumber *cachedResult = objc_getAssociatedObject(self, &kRemoteControllerKey);
    if (!cachedResult) {
        cachedResult = @([self nn_checkIfRemoteController]);
        objc_setAssociatedObject(self, &kRemoteControllerKey, cachedResult, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cachedResult.boolValue;
}

- (BOOL)nn_hasPendingStatusBarAppearanceUpdate {
    return [objc_getAssociatedObject(self, &kHasPendingStatusBarAppearanceUpdateKey) boolValue];
}

- (void)nn_setHasPendingStatusBarAppearanceUpdate:(BOOL)hasPendingStatusBarAppearanceUpdate {
    objc_setAssociatedObject(self, &kHasPendingStatusBarAppearanceUpdateKey, @(hasPendingStatusBarAppearanceUpdate), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
