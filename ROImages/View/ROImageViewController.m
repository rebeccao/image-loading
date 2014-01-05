//
//  ROImageViewController.m
//  ROImages
//
//  Created by Rebecca ODell on 12/16/13.
//  Copyright (c) 2013 Rebecca ODell. All rights reserved.
//  Abstract: The purpose of this controller is to allow the user to upload an image to the
//  server while displaying its upload progress.  Note: I chose AFNetworking 2.0
//  to upload the image because its serializer api's can easily format the request's multipart
//  form data.  Unfortunately this logic does not support background processing.  In order
//  to support background processing, NSURLSession's uploadTaskWithRequest:fromFile: must
//  be used.  The only way I can determine for this to work properly is to format the multipart
//  form data at the beginning of the file, but I think it can work.

//  POST /images.json HTTP/1.1
//  Host: ec2-184-72-25-67.us-west-1.compute.amazonaws.com:3000
//  Accept: * / *
//  Accept-Encoding: gzip, deflate
//  Content-Length: 2073441
//  Content-Type: multipart/form-data; boundary=Boundary+0xAbCdEfGbOuNdArY
//  Accept-Language: en;q=1, fr;q=0.9, de;q=0.8, zh-Hans;q=0.7, zh-Hant;q=0.6, ja;q=0.5
//  Connection: keep-alive
//  User-Agent: ROImages/1.0 (iPhone Simulator; iOS 7.0.3; Scale/2.00)

//  --Boundary+0xAbCdEfGbOuNdArY
//  Content-Disposition: form-data; name="image[image][]"

//  FILE
//  --Boundary+0xAbCdEfGbOuNdArY
//  Content-Disposition: form-data; name="image[image]"; filename="1_20280E5D-8E50-424A-812D-46046DC1DCC6-128-00000001407A3D82.jpg"
//  Content-Type: image/jpeg

//  ˇÿˇ‡ image file data

#import "ROImageViewController.h"
#import "AFNetworking.h"

@interface ROImageViewController ()

@end

@implementation ROImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = self.itemNumber;

    self.detailImage.image = self.itemImage;
 
    [self showProgressLoadingView:NO];
}

- (void)showProgressLoadingView:(BOOL)displayProgress {
    
    if (displayProgress) {
        self.uploadButton.enabled = NO;
        self.progressView.progress = 0.0f;
        self.progressView.hidden = NO;
        self.progressViewLabel.hidden = NO;
    } else {
        self.uploadButton.enabled = YES;
        self.progressView.hidden = YES;
        self.progressViewLabel.hidden = YES;
    }
}

- (IBAction)uploadButton:(id)sender {
    
    [self showProgressLoadingView:YES];
    
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSURL *docsDirURL = [NSURL fileURLWithPath:[docsDir stringByAppendingPathComponent:self.itemFilename]];
    
    NSData *imageData = [NSData dataWithContentsOfFile:[docsDirURL path]];
    
    NSDictionary *parameters = @{@"image": @{@"image": @[@"FILE"]}};
    NSLog(@"parameters = %@", parameters);
    
    // AFHTTPRequestSerializer creates the multipart form data request.
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    
    NSMutableURLRequest *request =
    [serializer multipartFormRequestWithMethod:@"POST" URLString:@"http://ec2-184-72-25-67.us-west-1.compute.amazonaws.com:3000/images.json"
                                    parameters:parameters
                     constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                         [formData appendPartWithFileData:imageData
                                                     name:@"image[image]"
                                                 fileName:self.itemFilename
                                                 mimeType:@"image/jpeg"];
                     }];
    
    // Use AFHTTPRequestOperationManager to create an AFHTTPRequestOperation from the NSMutableURLRequest
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    AFHTTPRequestOperation *operation =
    [manager HTTPRequestOperationWithRequest:request
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         NSLog(@"Success %@", responseObject);
                                         [self showProgressLoadingView:NO];
                                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         NSLog(@"Failure %@", error.description);
                                         [self showProgressLoadingView:NO];
                                     }];
    
    // Set the progress block of the operation.
    [operation setUploadProgressBlock:^(NSUInteger __unused bytesWritten,
                                        long long totalBytesWritten,
                                        long long totalBytesExpectedToWrite) {
        float progress = totalBytesWritten / (float)totalBytesExpectedToWrite;
        self.progressView.progress = progress;
    }];
    
    [operation start];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
