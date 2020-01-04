//
//  AP_Detail_ViewController.m
//  MapApp
//
//  Created by Thanh Hai Tran on 11/19/18.
//  Copyright © 2018 Thanh Hai Tran. All rights reserved.
//

#import "AP_Detail_ViewController.h"

@interface AP_Detail_ViewController ()<UIWebViewDelegate>
{
    IBOutlet UIButton * speaker, * loc;
    
    IBOutlet UIImageView * ava;
    
    IBOutlet UILabel * titleField, * infor;
    
    BOOL isOn;
    
    IBOutlet UIWebView * webView;
    
    AVAudioPlayer *audioPlayer;
}

@end

@implementation AP_Detail_ViewController

@synthesize detail;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    isOn = YES;
    
    speaker.hidden = [[detail getValueFromKey:@"exhibit_audio"] isEqualToString:@""] ? YES : NO;
    
    loc.hidden = [[detail getValueFromKey:@"image_location"] isEqualToString:@""] ? YES : NO;

    [speaker actionForTouch:@{} and:^(NSDictionary *touchInfo) {
        [speaker setImage:[UIImage imageNamed:isOn ? @"ic_stop_loa" : @"ic_play_loa"] forState:UIControlStateNormal];
        
        isOn =! isOn;
        
        [audioPlayer setVolume:isOn];
    }];
    
    [loc actionForTouch:@{} and:^(NSDictionary *touchInfo) {
        [[[EM_MenuView alloc] initWithLoc:@{@"url":[detail getValueFromKey:@"image_location"]}] show];
    }];
    
    [self loadDemos];
    
    infor.text = [[self getValue:@"lang"] isEqualToString:@"vi"] ? @"THÔNG TIN CHI TIẾT" : @"DETAIL INFORMATION";
    
    [self playAudio:[detail getValueFromKey:@"exhibit_audio"]];
}

- (void)playingAudioOnSeparateThread:(NSString *) path
{
    if(audioPlayer)
    {
        audioPlayer = nil;
    }
    
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:path];
    NSData *data = [NSData dataWithContentsOfURL:url];
    audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
    
    if (error == nil)
    {
        [audioPlayer play];
    }
}

- (void)playAudio:(NSString *)path
{
    [NSThread detachNewThreadSelector: @selector(playingAudioOnSeparateThread:) toTarget: self withObject: path];
}

- (void)loadDemos
{
    [ava imageUrl:[detail getValueFromKey: @"exhibit_image"]];
    
    titleField.text = [detail getValueFromKey: @"exhibit_name"];
    
    [webView loadHTMLString:[detail getValueFromKey: @"exhibit_description"] baseURL:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *changeColor = [NSString stringWithFormat:@"addCSSRule('html, body, div, p, span, a', 'color: #7A3C3C;')"];
    
    [webView stringByEvaluatingJavaScriptFromString:changeColor];
}


- (IBAction)didPressBack:(id)sender
{
    [audioPlayer stop];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
