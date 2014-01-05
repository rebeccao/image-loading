//
//  ROListTableViewController.m
//  ROImages
//  Abstract: This table view controller is the main view and is responsible for downloading
//  the images from the server.  Each image downloaded is saved full-size in the documents
//  directory then resized as a thumbnail and loaded into the row along with an image number,
//  and its filename.  A progress view tracks the download.
//
//  Note1: ROImageDownloader objects are stored in an NSMutableDictionary that's keyed by its
//  row number.  As images are received, they're removed from the NSMutableDictionary
//  to deallocate the object.  Note2: if user scrolls fast, the NSMutableDictionary will
//  queue up with many ROImageDownloader objects.  Use scrollViewDidEndDecelerating to remove
//  ROImageDownloader objects that are not visible.  Note3: tapping any row displays its detailed
//  larger view and allows the user to upload it to the server.
//
//  Created by Rebecca ODell on 12/16/13.
//  Copyright (c) 2013 Rebecca ODell. All rights reserved.

#import "ROListTableViewController.h"
#import "ROImageViewController.h"
#import "ROTableViewCell.h"
#import "ROImageDownloader.h"

static NSString *const ImageURLPath = @"http://ec2-184-72-25-67.us-west-1.compute.amazonaws.com:3000/download/";

@interface ROListTableViewController ()

@property (nonatomic, strong) NSMutableDictionary *imageDownloadsInProgress;

@end

@implementation ROListTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Hover.png"]];

    // Mutable dictionary of image download objects, one object for each image URL
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];

    // ROAppDelegate downloads the imageFilenameArray and assigns it to self.imageFilenames
    self.imageFilenames = [NSArray array];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // terminate all pending download connections
    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
    
    [self.imageDownloadsInProgress removeAllObjects];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"[self.imageFilenames count] = %u", [self.imageFilenames count]);
    return [self.imageFilenames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ROTableViewCell *cell = (ROTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ItemPrototypeCell"];
    
    cell.cellTitleLabel.text = [NSString stringWithFormat:@"Image %d", indexPath.row];
    cell.cellURLLabel.text = [self.imageFilenames objectAtIndex:indexPath.row];
    
    [cell.activityIndicator startAnimating];
    cell.progressView.progress = 0.0f;
    [cell.progressView setHidden:NO];
    
    cell.cellImage.image = nil;
    cell.cellImage.backgroundColor = [UIColor lightGrayColor];
    
    [self startImageDownloadForCell:cell andIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Table cell image support

- (void)startImageDownloadForCell:(ROTableViewCell *)cell andIndexPath:(NSIndexPath *)indexPath
{
    ROImageDownloader *imageDownloader = [self.imageDownloadsInProgress objectForKey:[NSNumber numberWithInteger:indexPath.row]];
    if (imageDownloader == nil)
    {
        imageDownloader = [[ROImageDownloader alloc] init];
        imageDownloader.downloadFilenameString = [self.imageFilenames objectAtIndex:indexPath.row];
        imageDownloader.downloadUrlString = [NSString stringWithFormat:@"%@%@",
                                             ImageURLPath, imageDownloader.downloadFilenameString];
        imageDownloader.cell = cell;
        imageDownloader.key  = [NSNumber numberWithInt:indexPath.row];

        NSLog(@"startImageDownloadForCell self.imageDownloadsInProgress = %@", self.imageDownloadsInProgress);
        
        imageDownloader.progressAction = ^(double bytesWritten, double bytesExpected) {
            double progress = bytesWritten / bytesExpected;
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.progressView.progress = (float) progress;
            });
        };

        __weak ROImageDownloader *weakImageDownloader = imageDownloader;

        [imageDownloader setCompletionHandler:^(BOOL success){
            // To conserve memory, resize the downloaded image to a thumbnail size
            UIImage *thumbnailImage = nil;
            if (success) {
                thumbnailImage = [self resizeImage:weakImageDownloader.downloadFilenameString];
            }
            dispatch_async(dispatch_get_main_queue(), ^{

                if (success) {
                    weakImageDownloader.cell.cellImage.image = thumbnailImage;
                    cell.cellImage.backgroundColor = [UIColor clearColor];
                    [weakImageDownloader.cell.activityIndicator stopAnimating];
                    [weakImageDownloader.cell.progressView setHidden:YES];
                }

                // Remove the IconDownloader from the in progress list in order to deallocate it.
                [self.imageDownloadsInProgress removeObjectForKey:[NSNumber numberWithInteger:indexPath.row]];
                //NSLog(@"setCompletionHandler self.imageDownloadsInProgress = %@", self.imageDownloadsInProgress);
            });
        }];
        [self.imageDownloadsInProgress setObject:imageDownloader forKey:[NSNumber numberWithInteger:indexPath.row]];
        [imageDownloader startDownload];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // self.imageDownloadsInProgress downloads and displays the imageDownloader objects them as the
    // table is scrolled.  Fast scrolling will cause self.imageDownloadsInProgress to be queued up
    // with download, so downloads will be processed even if they are no longer visible.  For
    // imageDownloaders that are not visible after scrolling has stopped, cancel their download
    // and remove them from self.imageDownloadsInProgress.
    NSLog(@"scrollViewDidScroll self.imageDownloadsInProgress = %@", self.imageDownloadsInProgress);
    
    // First create a set of visible rows from the visible indexPaths
    NSArray *visibleIndexPathsArray = [self.tableView indexPathsForVisibleRows];
    NSMutableArray *visibleRows = [NSMutableArray arrayWithCapacity:5];
    for (NSIndexPath *visibleIndexPath in visibleIndexPathsArray) {
        [visibleRows addObject:[NSNumber numberWithInteger:visibleIndexPath.row]];
    }
    NSSet *visibleRowSet = [NSSet setWithArray:visibleRows];
    NSLog(@"scrollViewDidScroll visibleRowSet = %@", visibleRowSet);
    
    // Then create an array of self.imageDownloadsInProgress keys
    NSArray *imageDownloaderIndexPathsKeys = [self.imageDownloadsInProgress allKeys];
    NSLog(@"scrollViewDidScroll imageDownloaderIndexPathsKeys = %@", imageDownloaderIndexPathsKeys);

    // Loop thru the imageDownloaderIndexPathsKeys.  If it's not a visible row, retrieve
    // the row's imageDownloader object to cancel its download and remove it from
    // self.imageDownloadsInProgress
    ROImageDownloader *imageDownloader = [[ROImageDownloader alloc] init];
    for (NSNumber *rowKey in imageDownloaderIndexPathsKeys) {
        if (![visibleRowSet containsObject:rowKey]) {
            NSLog(@"scrollViewDidScroll Remove rowKey = %@", rowKey);
            imageDownloader = [self.imageDownloadsInProgress objectForKey:rowKey];
            [imageDownloader cancelDownload];
            [self.imageDownloadsInProgress removeObjectForKey:rowKey];
        }
    }
    NSLog(@"scrollViewDidScroll self.imageDownloadsInProgress = %@", self.imageDownloadsInProgress);
}

- (UIImage *)resizeImage:(NSString *)imageFilename
{
    // To conserve memory, resize the downloaded image to a thumbnail size
    // keeping its aspect ratio in tack
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSURL *docsDirURL = [NSURL fileURLWithPath:[docsDir stringByAppendingPathComponent:imageFilename]];
    
    if (!docsDirURL) {
        return nil;
    }
    
    UIImage *image = [UIImage imageWithContentsOfFile:[docsDirURL path]];
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = 80.0/60.0;
    
    if(imgRatio!=maxRatio){
        if(imgRatio < maxRatio){
            imgRatio = 60.0 / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = 60.0;
        }
        else{
            imgRatio = 80.0 / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = 80.0;
        }
    }
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

#pragma mark - storyboard segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // If the user selects a row, transition to its detail view with an
    // option to upload the image
    if ([segue.identifier isEqualToString:@"ItemDetails"]) {
        
        ROImageViewController *imageViewController = segue.destinationViewController;
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ROTableViewCell *cell = (ROTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        imageViewController.itemNumber   = cell.cellTitleLabel.text;
        imageViewController.itemFilename = cell.cellURLLabel.text;
        imageViewController.itemImage    = cell.cellImage.image;
    }
}

@end
