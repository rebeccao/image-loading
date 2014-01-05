//
//  ROAppDelegate.m
//  ROImages
//  Abstract: Application delegate for the Image Download/Upload sample
//  Download the image list in the background using NSURLConnection.  Once
//  its received, create and load ROListTableViewController
//
//  Created by Rebecca ODell on 12/16/13.
//  Copyright (c) 2013 Rebecca ODell. All rights reserved.
//

#import "ROAppDelegate.h"
#import "ROListTableViewController.h"
#import <CFNetwork/CFNetwork.h>  // to access the kCFURLErrorNotConnectedToInternet error code.
#import "AFNetworkActivityLogger.h"

static NSString *const DataFeed = @"http://ec2-184-72-25-67.us-west-1.compute.amazonaws.com:3000/download/index.json";

@interface ROAppDelegate ()
@property (nonatomic, strong) NSURLConnection *dataFeedConnection;
@property (nonatomic, strong) NSMutableData *imageListData;
@end

@implementation ROAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[[AFNetworkActivityLogger sharedLogger] startLogging];
    //[[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelError];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:DataFeed]];
    self.dataFeedConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    
    // Test the validity of the URL
    NSAssert(self.dataFeedConnection != nil, @"Failure to create URL connection.");
    
    // show in the status bar that network activity is starting
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    return YES;
}

#pragma mark - Error Support

- (void)handleError:(NSError *)error
{
    NSString *errorMessage = [error localizedDescription];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry, Cannot Show Images"
														message:errorMessage
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.imageListData = [NSMutableData data];    // start off with new data
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.imageListData appendData:data];  // append incoming data
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([error code] == kCFURLErrorNotConnectedToInternet)
	{
        // determine if it's a connection error
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No Connection Error"
															 forKey:NSLocalizedDescriptionKey];
        NSError *noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain
														 code:kCFURLErrorNotConnectedToInternet
													 userInfo:userInfo];
        [self handleError:noConnectionError];
    }
	else
	{
        // handle all other errors generically
        [self handleError:error];
    }
    
    self.dataFeedConnection = nil;   // release our connection
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.dataFeedConnection = nil;   // release our connection
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSError *jsonParsingError = nil;
    NSArray *imageFilenameArray = [NSJSONSerialization JSONObjectWithData:self.imageListData
                                                                  options:0
                                                                    error:&jsonParsingError];
    NSLog(@"connectionDidFinishLoading: imageFilenameArray = %@", imageFilenameArray);

    // The root rootViewController is the only child of the navigation controller
    ROListTableViewController *listTableViewController = (ROListTableViewController*)
                                                         [(UINavigationController*)self.window.rootViewController topViewController];
    
    listTableViewController.imageFilenames = imageFilenameArray;
    
    // tell the table view to reload its data
    [listTableViewController.tableView reloadData];

    self.imageListData = nil;
}

#pragma mark - AppDelegates
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
