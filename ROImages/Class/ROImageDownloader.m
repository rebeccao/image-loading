//
//  ROImageDownloader.m
//  ROImages
//  Abstract: Use NSURLSession's downloadTask to download images from the server to
//  a temporary directory.  When the download completes for each image, save it to
//  the documents directory and call the downloadLoader's completionHandler.  Note
//  the downloadTask supports background processing, but this logic is not included.
//
//  Created by Rebecca ODell on 12/16/13.
//  Copyright (c) 2013 Rebecca ODell. All rights reserved.
//

#import "ROImageDownloader.h"

@interface ROImageDownloader ()

@end

@implementation ROImageDownloader

#pragma mark - Start Download

- (void)startDownload
{
    // Create a new session and start the image download
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig
                                                                 delegate:self
                                                            delegateQueue:nil];
    
    self.downloadTask = [defaultSession downloadTaskWithURL:[NSURL URLWithString:self.downloadUrlString]];

    [self.downloadTask resume];
}

- (void)cancelDownload
{
    NSLog(@"cancelDownload Key = %@", self.key);
    if (self.downloadTask)
    {
        [self.downloadTask cancel];
        self.downloadTask = nil;
    }
}

#pragma mark - NSURLSessionDownloadDelegate

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSLog(@"URLSession:downloadTask:didFinishDownloadingToURL: Key =%@", self.key);
    
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                           inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = URLs[0];
    NSURL *destinationPath = [documentsDirectory URLByAppendingPathComponent:self.downloadFilenameString];

    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:destinationPath error:NULL];
    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:location toURL:destinationPath error:&error];

    if (self.completionHandler) {
        self.completionHandler(success);
    }
    
    if(downloadTask == self.downloadTask) {
        self.downloadTask = nil;
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if (downloadTask == self.downloadTask && self.progressAction)
    {
        self.progressAction((double)totalBytesWritten, (double)totalBytesExpectedToWrite);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // This is called at the end of every download.  An error occurs if the download was cancelled.
    // Otherwise error is null.
    //NSLog(@"URLSession:task:didCompleteWithError: Key =%@, error = %@", self.key, error);
    if (error) {
        if (self.completionHandler)
            self.completionHandler(NO);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
}


@end
