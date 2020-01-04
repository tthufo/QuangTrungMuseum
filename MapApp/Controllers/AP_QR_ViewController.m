//
//  AP_QR_ViewController.m
//  MapApp
//
//  Created by Thanh Hai Tran on 11/19/18.
//  Copyright © 2018 Thanh Hai Tran. All rights reserved.
//

#import "AP_QR_ViewController.h"

#import "DYQRCodeDecoderViewController.h"

#import "AP_Detail_ViewController.h"

@interface AP_QR_ViewController ()
{
    IBOutlet UIButton * back, * done ;
    
    IBOutlet UIImageView * bar;
}

@end

@implementation AP_QR_ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [back actionForTouch:@{} and:^(NSDictionary *touchInfo) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    
    [bar actionForTouch:@{} and:^(NSDictionary *touchInfo) {
        [self didShowQR];
    }];
    
    [self didShowQR];
}

- (IBAction)didShowQR
{
    DYQRCodeDecoderViewController *vc = [[DYQRCodeDecoderViewController alloc] initWithCompletion:^(BOOL succeeded, NSString *result) {
        if (succeeded) {
            [[LTRequest sharedInstance] didRequestInfo:@{@"absoluteLink":[NSString stringWithFormat:@"http://222.252.17.86:9017/api/Exhibit/info?id=%@&lang=%@", result, [self getValue:@"lang"]],
                                                         @"method":@"GET",
                                                         @"overrideLoading":@(1),
                                                         @"host":self,
                                                         @"overrideAlert":@(1)
                                                         } withCache:^(NSString *cacheString) {
                                                             
                                                         } andCompletion:^(NSString *responseString, NSString *errorCode, NSError *error, BOOL isValidated) {
                                                             
                                                             if([errorCode isEqual:[NSNull null]])
                                                             {
                                                                 [self showToast:@"Thông tin hiện vật không tồn tại" andPos:0];
                                                                 
                                                                 return ;
                                                             }
                                                             
                                                             if(![errorCode isEqualToString:@"200"])
                                                             {
                                                                 [self showToast:@"Lỗi xảy ra, mời bạn thử lại sau" andPos:0];
                                                                 
                                                                 return ;
                                                             }
                                                             
                                                             
                                                             AP_Detail_ViewController * detail = [AP_Detail_ViewController new];
                                                             
                                                             detail.detail = [responseString objectFromJSONString];
                                                             
                                                             [self.navigationController pushViewController:detail animated:YES];
                                                         }];
        } else {
            [self showToast:@"Không tìm thấy thông tin, mời bạn thử lại sau" andPos:0];
        }
    }];
    
    vc.needsScanAnnimation = YES;
    
    [self presentViewController:vc animated:YES completion:^{
        
        CGRect frame = done.frame;
        
        frame.origin.x = (screenWidth1 - 40) / 2;
        
        frame.origin.y = (screenHeight1 - 60);
        
        done.frame = frame;
        
        [vc.view addSubview:done];
        
        [done actionForTouch:@{} and:^(NSDictionary *touchInfo) {
            [vc dismissViewControllerAnimated:YES completion:nil];
        }];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
