//
//  AP_Notification_ViewController.m
//  MapApp
//
//  Created by Thanh Hai Tran on 12/21/18.
//  Copyright © 2018 Thanh Hai Tran. All rights reserved.
//

#import "AP_Notification_ViewController.h"

#import "InfinitePagingView.h"

@interface AP_Notification_ViewController ()<InfinitePagingViewDelegate>
{
    IBOutlet InfinitePagingView * banner;
    
    IBOutlet UIPageControl * pageControl;
    
    IBOutlet UIButton * back;
    
    IBOutlet UIWebView * content;

    IBOutlet NSLayoutConstraint * height;
    
    NSTimer * timer;
    
    int currentIndexing, total;
}

@end

@implementation AP_Notification_ViewController

@synthesize detailId;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    banner.delegate = self;
    
    [banner pageSize:CGSizeMake(screenWidth1, screenWidth1 * 9 / 16)];
    
    height.constant = screenWidth1 * 9 / 16;
    
//    [self reloadBanner:@[@"https://www.researchgate.net/profile/Diane_Gan/publication/309212939/figure/fig10/AS:668879755939850@1536484769394/Email-Harvesting-in-Progress.ppm", @"https://www.researchgate.net/profile/Diane_Gan/publication/309212939/figure/fig10/AS:668879755939850@1536484769394/Email-Harvesting-in-Progress.ppm", @"https://www.researchgate.net/profile/Diane_Gan/publication/309212939/figure/fig10/AS:668879755939850@1536484769394/Email-Harvesting-in-Progress.ppm"]];
//
//    [self initTimer];
    
    [back actionForTouch:@{} and:^(NSDictionary *touchInfo) {
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self didRequestDetail];
}

- (void)didRequestDetail
{
    [[LTRequest sharedInstance] didRequestInfo:@{@"absoluteLink":[NSString stringWithFormat:@"http://222.252.17.86:9017/api/Event/%@?lang=%@", detailId, [self getValue:@"lang"]],
                                                 @"overrideAlert":@(1),
                                                 @"method":@"GET"
                                                 } withCache:^(NSString *cacheString) {
                                                     
                                                 } andCompletion:^(NSString *responseString, NSString *errorCode, NSError *error, BOOL isValidated) {
                                                     
                                                     if([errorCode isEqualToString:@"200"])
                                                     {
                                                         NSDictionary * noti = [responseString objectFromJSONString];
                                                                                                                  
                                                         [self reloadBanner:noti[@"images"]];
                                                         
                                                         [self initTimer];
                                                         
                                                         [content loadHTMLString:noti[@"notification_content"] baseURL:nil];
                                                     }
                                                     
                                                 }];
}

- (void)initTimer
{
    if(timer)
    {
        [timer invalidate];
        
        timer = nil;
    }
    
    timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(timerChange) userInfo:nil repeats:YES];
}

- (void)timerChange
{
    [banner scrollToNextPage];
    
    currentIndexing = banner.currentPageIndex == pageControl.numberOfPages - 1 ? 0 : banner.currentPageIndex + 1;
}

- (void)cleanBanner
{
    [banner removePageView];
}

- (void)reloadBanner:(NSArray*)urls
{
    [self cleanBanner];
    
    pageControl.numberOfPages = urls.count;
    
    
    for (NSUInteger i = 0; i < urls.count; ++i)
    {
        UIImageView *page = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, screenWidth1, banner.frame.size.height)];
        
        page.contentMode = UIViewContentModeScaleAspectFill;
        
        page.clipsToBounds = YES;
        
        [page imageUrl:urls[i][@"image_name"]];
        
        [banner addPageView:page];
    }
    
    [self initTimer];
}


- (void)pagingView:(InfinitePagingView *)pagingView didEndDecelerating:(UIScrollView *)scrollView atPageIndex:(NSInteger)pageIndex
{
    pageControl.currentPage = pageIndex;
    
    currentIndexing = banner.currentPageIndex == pageControl.numberOfPages - 1 ? 0 : banner.currentPageIndex + 1;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
