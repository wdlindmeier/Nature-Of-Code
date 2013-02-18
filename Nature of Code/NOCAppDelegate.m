//
//  WDLAppDelegate.m
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCAppDelegate.h"
#import "NOCTableOfContentsViewController.h"

#if DEBUG
#import "NOCWaveMatrixSketchViewController.h"
#endif

@implementation NOCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
#if DEBUG
    
    // self.viewController = [[NOCWaveMatrixSketchViewController alloc] init];
    
#endif
    
    if(!self.viewController){

        NOCTableOfContentsViewController *tocViewController = [[NOCTableOfContentsViewController alloc] init];
        UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:tocViewController];
        self.viewController = nvc;
        
    }
    
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
