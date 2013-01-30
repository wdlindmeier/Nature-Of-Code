//
//  WDLAppDelegate.m
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCAppDelegate.h"

#import "NOCTableOfContentsViewController.h"

@implementation NOCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // TODO: Set appearances
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    NOCTableOfContentsViewController *tocViewController = [[NOCTableOfContentsViewController alloc] init];
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:tocViewController];
    self.viewController = nvc;
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
