//
//  ROImageDownloader.h
//  ROImages
//
//  Created by Rebecca ODell on 12/16/13.
//  Copyright (c) 2013 Rebecca ODell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ROTableViewCell.h"

typedef void (^ROProgressBlock)(double totalBytesWritten, double bytesExpected);

@class ROItemRecord;

@interface ROImageDownloader : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, strong) NSString *downloadUrlString;
@property (nonatomic, strong) NSString *downloadFilenameString;

@property (nonatomic, strong) ROTableViewCell *cell;
@property (nonatomic, strong) NSNumber *key;
@property (strong) ROProgressBlock progressAction;
@property (nonatomic, copy) void (^completionHandler)(BOOL);

- (void)startDownload;
- (void)cancelDownload;

@end
