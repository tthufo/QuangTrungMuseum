//
//  AP_Map_ViewController.m
//  MapApp
//
//  Created by Thanh Hai Tran on 4/10/18.
//  Copyright © 2018 Thanh Hai Tran. All rights reserved.
//

#import "AP_Map_ViewController.h"

#import <GoogleMaps/GoogleMaps.h>

#import "AP_Web_ViewController.h"

#import "AP_Intro_ViewController.h"

#import "GMUGeoJSONParser.h"

#import "GMUGeometryRenderer.h"

#import "GMUFeature.h"

#import "AP_Web_List_ViewController.h"

#import "AP_Information_ViewController.h"

#import "AP_QR_ViewController.h"

#import "AP_Detail_ViewController.h"

#import "AP_Notification_ViewController.h"

#import "DYQRCodeDecoderViewController.h"

#import "AP_Intro_ViewController.h"

@interface AP_Map_ViewController ()<GMSMapViewDelegate>
{
    IBOutlet UIImageView * hand;
    
    IBOutlet UIView * top, * bar;
    
    IBOutlet UITextField * search;
    
    IBOutlet NSLayoutConstraint * topBar;
    
    NSMutableArray * dataList, * dataPoly, * markerList, * polyList, * userList, * userLine;
    
    NSArray * sign;
    
    IBOutlet GMSMapView * mapView;
    
    IBOutlet DropButton * menu;
    
    BOOL isStreet, isShow, isEnable, isLine;
    
    IBOutlet UIButton * changeMap, * menuMap, * done;
    
    GMSMarker * mainMarker, * searchMarker, * polyMarker, * layerMarker;
    
    GMSURLTileLayer *layer;
    
    GMUGeometryRenderer *renderer, *rendererAll;
    
    GMUGeoJSONParser *parser, *parserAll;
    
    KeyBoard * kb;
    
    NSString * uniqueID;
    
    NSTimer * time, * track;
    
    UIActivityIndicatorView * indicator;
    
    BOOL isOn;
    
    GMSPolygon *polyline;
    
    IBOutlet UIImageView * scroll;
}

@end

@implementation AP_Map_ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO
                                            withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11"))
    {
        topBar.constant = [self isIphoneX] ? 3 : 20;
    }
    
    markerList = [NSMutableArray new];
    
    polyList = [NSMutableArray new];
    
    userList = [NSMutableArray new];
    
    userLine = [NSMutableArray new];
    
    indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
    
    indicator.transform = CGAffineTransformMakeScale(1.75, 1.75);
    
    [indicator hidesWhenStopped];
    
    [indicator stopAnimating];
    
    [indicator setColor:[UIColor blackColor]];
    
    [mapView addSubview:indicator];
    
    isStreet = YES;
    
    uniqueID = @"";

    
    isShow = [self getObject:@"setting"];
    
    dataList = [@[] mutableCopy];
    
    dataPoly = [@[] mutableCopy];

    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:[self lat]
                                                            longitude:[self lng]
                                                                 zoom:15];

    mapView.camera = camera;
    
    mapView.delegate = self;
    
    
    search.inputAccessoryView = [self toolBar];
    
    mapView.mapType = kGMSTypeSatellite;
    
    NSDictionary * dict = nil;

    if([self getObject:@"setting"])
    {
        dict = [self getObject:@"setting"];
    }
    else
    {
        dict = @{@"date":[[NSDate date] stringWithFormat:@"dd/MM/yyyy"], @"gender":@"0", @"show":@"0"};
    }
    
    [self didSetDate:[self getDateFromDateString:dict[@"date"]] andGender:dict[@"gender"]];
    
    if(isShow)
    {
        [changeMap setImage:[UIImage imageNamed:[dict[@"show"] boolValue] ? @"ic_off_compass_zodiac" : @"ic_show_compass_zodiac"] forState:UIControlStateNormal];
    }
    else
    {
        [changeMap setImage:[UIImage imageNamed:@"ic_show_compass_zodiac"] forState:UIControlStateNormal];
    }

    [self performSelector:@selector(prefixRequest) withObject:nil afterDelay:0.5];


    [[Permission shareInstance] didReturnHeading:^(float magneticHeading, float trueHeading) {
        
        CGAffineTransform rotate = CGAffineTransformMakeRotation(DegreesToRadians(-magneticHeading));
        
        [hand setTransform:rotate];
        
        if(isShow)
        {
            [self didChangeAngle:magneticHeading];
        }
        
        if([[self getObject:@"setting"][@"show"] boolValue])
        {
            [mapView animateToBearing:-trueHeading];
        }
        
    }];
    
    
//    [self didRequestForPoints];
    
    
    [menu actionForTouch:@{} and:^(NSDictionary *touchInfo) {
        
        [self.view endEditing:YES];
        
        [[[EM_MenuView alloc] initWithMenu:@{}] showWithCompletion:^(int index, id object, EM_MenuView *menu) {
            switch (index) {
                case 1:
                {
                    [self addValue:[[self getValue:@"lang"] isEqualToString:@"vi"] ? @"en" : @"vi" andKey:@"lang"];
                    
                    search.inputAccessoryView = [self toolBar];
                }
                    break;
                case 2:
                {
                    [self didLoadNotification];
                }
                    break;
                case 3:
                {
                    [self.navigationController pushViewController:[AP_Intro_ViewController new] animated:YES];
                }
                    break;
                case 4:
                {
                    [self didPressMapType:menu];
                }
                    break;
                default:
                    break;
            }
        }];
    }];
    
    
    [self currentMaker:[self lat] andLong:[self lng]];
    
    
    [self drawLine];
    
    CGRect rect = bar.frame;
    
    rect.size.width = screenWidth1;
    
    rect.origin.y = screenHeight1 ;
    
    rect.origin.x = 0;
    
    bar.frame = rect;
    
    [self.view addSubview:bar];
    
    [self didAddLayerTile];

    
    scroll.image = [SWNinePatchImageFactory createResizableNinePatchImage:[UIImage imageNamed:@"bg_search.9"]];
    
    if([[self getValue:@"noti"] isEqualToString:@"1"])
    {
        [self didLoadNotification];
    }
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

- (void)didLoadNotification
{
    [[LTRequest sharedInstance] didRequestInfo:@{@"absoluteLink":[NSString stringWithFormat:@"http://222.252.17.86:9017/api/Event?lang=%@", [self getValue:@"lang"]],
                                                 @"overrideAlert":@(1),
                                                 @"method":@"GET"
                                                 } withCache:^(NSString *cacheString) {
                                                     
                                                 } andCompletion:^(NSString *responseString, NSString *errorCode, NSError *error, BOOL isValidated) {
                                                     
                                                     if([errorCode isEqualToString:@"200"])
                                                     {
                                                         NSArray * noti = [responseString objectFromJSONString][@"array"];
                                                         
                                                         if (noti.count == 0) {
                                                             return;
                                                         }
                                                         
                                                         [[[EM_MenuView alloc] initWithNotification:@{@"data":noti}] showWithCompletion:^(int index, id object, EM_MenuView *menu) {

                                                             [menu close];
                                                             
                                                             if(object) {
                                                                 
                                                                 NSString * detailId = [object[@"data"] getValueFromKey:@"id"];
                                                                 
                                                                 AP_Notification_ViewController * notification = [AP_Notification_ViewController new];
                                                                 
                                                                 notification.detailId = detailId;
                                                                 
                                                                 [self presentViewController:notification animated:YES completion:nil];
                                                             }

                                                         }];
                                                     }
                                                     
                                                 }];
}

- (void)didLoadJSON
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"gami_diadiem" ofType:@"geojson"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    [dataList removeAllObjects];
    
    for(NSDictionary * dict in [data objectFromJSONData][@"features"])
    {
        [dataList addObject:dict];
    }
    
    [self didLayoutPoints];
}

- (void)drawLine
{
    [polyList removeAllObjects];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"gami_tuyenthamquan" ofType:@"geojson"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    for(NSDictionary * dict in [data objectFromJSONData][@"features"])
    {
        GMSMutablePath *path = [GMSMutablePath path];
        for(NSArray * array in [dict[@"geometry"][@"coordinates"] firstObject])
        {
            [path addCoordinate:CLLocationCoordinate2DMake([array[1] floatValue], [array[0] floatValue])];
        }
        GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
        
        polyline.accessibilityValue = @"0";
        
        polyline.accessibilityLabel = [dict[@"properties"] bv_jsonStringWithPrettyPrint:true];
        
        polyline.tappable = YES;
        
        [polyList addObject:polyline];
        
        polyline.strokeWidth = 5;
        
        polyline.strokeColor = [UIColor orangeColor];
        
        polyline.map = mapView;
    }
}


- (void)tracking
{
    if(track)
    {
        [track invalidate];
        
        track = nil;
    }
    
    [userList removeAllObjects];
    
    track = [NSTimer scheduledTimerWithTimeInterval:55 target:self selector:@selector(didRequestClosest) userInfo:nil repeats: YES];
}

- (void)stopTracking
{
    if(track)
    {
        [track invalidate];
        
        track = nil;
    }
    
    [userList removeAllObjects];
    
    if(userLine.count != 0)
    {
        for(GMSPolyline * line in userLine)
        {
            line.map = nil;
        }
    }
}

-(void)didRequestClosest
{
    NSString * lat = [NSString stringWithFormat:@"%f", [self nearestPolylineLocationToCoordinate:CLLocationCoordinate2DMake([self lat], [self lng])].latitude];
    
    NSString * lng = [NSString stringWithFormat:@"%f", [self nearestPolylineLocationToCoordinate:CLLocationCoordinate2DMake([self lat], [self lng])].longitude];
    
    [userList addObject:@[lat,lng]];
    
    if(userLine.count != 0)
    {
        for(GMSPolyline * line in userLine)
        {
            line.map = nil;
        }
    }
    
    [userLine removeAllObjects];
    
    GMSMutablePath *path = [GMSMutablePath path];
    
    float i = 0;
    
    for(NSArray * array in userList)
    {
//        i += 0.00001;
        [path addCoordinate:CLLocationCoordinate2DMake([array[0] floatValue] + i, [array[1] floatValue] + i)];
    }
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    
    [userLine addObject:polyline];
    
    polyline.strokeWidth = 5;
    
    polyline.strokeColor = [UIColor redColor];
    
    polyline.map = mapView;
}

- (CLLocationCoordinate2D)nearestPolylineLocationToCoordinate:(CLLocationCoordinate2D)coordinate {
    GMSPolyline *bestPolyline;
    double bestDistance = DBL_MAX;
    CGPoint bestPoint;
    CGPoint originPoint = CGPointMake(coordinate.longitude, coordinate.latitude);
    
    for (GMSPolyline *polyline in polyList) {
        
        if([polyline.accessibilityValue isEqualToString:@"1"])
        {
            if (polyline.path.count < 2) {
                return kCLLocationCoordinate2DInvalid;
            }
            
            for (NSInteger index = 0; index < polyline.path.count - 1; index++) {
                CLLocationCoordinate2D startCoordinate = [polyline.path coordinateAtIndex:index];
                CGPoint startPoint = CGPointMake(startCoordinate.longitude, startCoordinate.latitude);
                CLLocationCoordinate2D endCoordinate = [polyline.path coordinateAtIndex:(index + 1)];
                CGPoint endPoint = CGPointMake(endCoordinate.longitude, endCoordinate.latitude);
                double distance;
                CGPoint point = [self nearestPointToPoint:originPoint onLineSegmentPointA:startPoint pointB:endPoint distance:&distance];
                
                if (distance < bestDistance) {
                    bestDistance = distance;
                    bestPolyline = polyline;
                    bestPoint = point;
                }
            }
        }
    }
    
    return CLLocationCoordinate2DMake(bestPoint.y, bestPoint.x);
}

- (CGPoint)nearestPointToPoint:(CGPoint)origin onLineSegmentPointA:(CGPoint)pointA pointB:(CGPoint)pointB distance:(double *)distance {
    CGPoint dAP = CGPointMake(origin.x - pointA.x, origin.y - pointA.y);
    CGPoint dAB = CGPointMake(pointB.x - pointA.x, pointB.y - pointA.y);
    CGFloat dot = dAP.x * dAB.x + dAP.y * dAB.y;
    CGFloat squareLength = dAB.x * dAB.x + dAB.y * dAB.y;
    CGFloat param = dot / squareLength;
    
    CGPoint nearestPoint;
    if (param < 0 || (pointA.x == pointB.x && pointA.y == pointB.y)) {
        nearestPoint.x = pointA.x;
        nearestPoint.y = pointA.y;
    } else if (param > 1) {
        nearestPoint.x = pointB.x;
        nearestPoint.y = pointB.y;
    } else {
        nearestPoint.x = pointA.x + param * dAB.x;
        nearestPoint.y = pointA.y + param * dAB.y;
    }
    
    CGFloat dx = origin.x - nearestPoint.x;
    CGFloat dy = origin.y - nearestPoint.y;
    *distance = sqrtf(dx * dx + dy * dy);
    
    return nearestPoint;
}


- (void)getAreaInfo
{
    if(time)
    {
        [time invalidate];
        
        time = nil;
    }
    
    time = [NSTimer scheduledTimerWithTimeInterval: 0.8 target:self selector:@selector(didRequestForAreaInfo) userInfo:nil repeats: NO];
}

- (NSDate *)getDateFromDateString:(NSString *)dateString
{
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy"];
    NSDate *date = [dateFormatter dateFromString:dateString];
    return date;
}

- (void)didGotoPosition:(float)lat andLong:(float)lng andZoom:(float)zoom
{
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:lat
                                                            longitude:lng
                                                                 zoom:zoom];
    [mapView animateToCameraPosition:camera];
}

- (void)didAddLayerTile
{
    GMSTileURLConstructor urls = ^(NSUInteger x, NSUInteger y, NSUInteger zoom) {
        
        NSString * url = [NSString stringWithFormat:@"http://103.7.41.156:8095/BaoTangQuangTrung/%lu/%lu/%lu.png", (unsigned long)zoom, (unsigned long)x, (unsigned long)y ];
        
        
//        NSString *url = [NSString stringWithFormat:@"%@/wms.svc?z=%lu&x=%lu&y=%lu&layer=%@", infoPlist[@"host"],
//                        (unsigned long)zoom, (unsigned long)x, (unsigned long)cor, uniqueID];
        
        return [NSURL URLWithString:url];
    };

    layer = [GMSURLTileLayer tileLayerWithURLConstructor:urls];

    layer.zIndex = -1;
    
    layer.map = mapView;
}

- (void)didRender:(NSString*)geoJson andLat:(float)lat andLng:(float)lng andInfo:(NSString*)info
{
    NSData* data = [geoJson dataUsingEncoding:NSUTF8StringEncoding];

    if(parser)
    {
        parser = nil;
    }

    parser = [[GMUGeoJSONParser alloc] initWithData:data];

    [parser parse];

    if(renderer)
    {
        [renderer clear];

        renderer = nil;
    }

    renderer = [[GMUGeometryRenderer alloc] initWithMap:mapView
                                             geometries:parser.features];
    [renderer render];

    
    if(![geoJson isEqualToString:@""])
    {
        [self didGotoPosition:lat andLong:lng andZoom:17];
    }
    
    if(polyMarker)
    {
        polyMarker.map = nil;
        
        polyMarker = nil;
    }
    
    polyMarker = [[GMSMarker alloc] init];
    polyMarker.position =  CLLocationCoordinate2DMake(lat, lng);
    polyMarker.accessibilityLabel = info;
    polyMarker.icon = [GMSMarker markerImageWithColor:[UIColor yellowColor]];//[UIImage imageNamed:@"trans"];
    polyMarker.map = mapView;
    polyMarker.tappable = NO;
    mapView.selectedMarker = polyMarker;
}

- (void)didRequestPositionInfo:(NSString*)loId andLat:(float)lat andLng:(float)lng
{
    [[LTRequest sharedInstance] didRequestInfo:@{@"CMD_CODE":[NSString stringWithFormat:@"point/lo/info/%@", loId],
                                                 @"overrideAlert":@(1),
                                                 @"method":@"GET"
                                                 } withCache:^(NSString *cacheString) {
                                                     
                                                 } andCompletion:^(NSString *responseString, NSString *errorCode, NSError *error, BOOL isValidated) {
                                                     
                                                     if([errorCode isEqualToString:@"200"])
                                                     {
                                                         NSString * loInfo = responseString;

                                                         [[LTRequest sharedInstance] didRequestInfo:@{@"CMD_CODE":[NSString stringWithFormat:@"point/lo/geojson/%@", [responseString objectFromJSONString][@"gid"]],
                                                                                                      @"overrideAlert":@(1),
                                                                                                      @"method":@"GET"
                                                                                                      } withCache:^(NSString *cacheString) {

                                                                                                      } andCompletion:^(NSString *responseString, NSString *errorCode, NSError *error, BOOL isValidated) {

                                                                                                          if([errorCode isEqualToString:@"200"])
                                                                                                          {
                                                                                                              [self didRender:responseString andLat:lat andLng:lng andInfo:loInfo];                                                                                 }
                                                                                                      }];
                                                     }
                                                     
                                                 }];
}

- (void)didRequestForAreaInfo
{
    if([[self getObject:@"setting"][@"show"] boolValue])
    {
        return;
    }
    
    if(mapView.camera.zoom >= 18)
    {
        CLLocationCoordinate2D topRight = [mapView.projection visibleRegion].farRight;
        
        CLLocationCoordinate2D bottomLeft = [mapView.projection visibleRegion].nearLeft;

        [[LTRequest sharedInstance] didRequestInfo:@{@"CMD_CODE":@"point/lo/inbound",
                                                     @"xmin":@(bottomLeft.longitude),
                                                     @"xmax":@(topRight.longitude),
                                                     @"ymin":@(bottomLeft.latitude),
                                                     @"ymax":@(topRight.latitude),
                                                     @"layer":uniqueID,
                                                     @"overrideAlert":@(1),
                                                     @"postFix":@"point/lo/inbound",
                                                     } withCache:^(NSString *cacheString) {
                                                         
                                                     } andCompletion:^(NSString *responseString, NSString *errorCode, NSError *error, BOOL isValidated) {
                                                         
                                                         [self hideSVHUD];
                                                         
                                                         if(!responseString)
                                                         {
                                                             return;
                                                         }
                                                         
                                                         if([errorCode isEqualToString:@"200"])
                                                         {
                                                             [self clearPolygon];
                                                             
                                                             NSArray * array = [responseString objectFromJSONString][@"array"];
                                                             
                                                                 for(NSDictionary * obj in array)
                                                                 {
                                                                     NSString * geo = obj[@"geojson"];
                                                                     
                                                                     NSDictionary * cors = [geo objectFromJSONString];
                                                                     
                                                                     NSMutableArray * points = [NSMutableArray new];
                                                                     
                                                                     for(NSArray * arr in cors[@"coordinates"][0][0])
                                                                     {
                                                                         NSDictionary * point = @{@"lat":arr[0], @"lng":arr[1]};
                                                                         
                                                                         [points addObject:point];
                                                                     }

                                                                     GMSMutablePath *path = [GMSMutablePath path];
                                                                     
                                                                     for(NSDictionary * dict in points)
                                                                     {
                                                                         [path addCoordinate:CLLocationCoordinate2DMake([dict[@"lng"] floatValue], [dict[@"lat"] floatValue])];
                                                                     }
                                                                     
                                                                     GMSPolygon *polyline = [GMSPolygon polygonWithPath:path];
                                                                     polyline.strokeWidth = 3;
                                                                     polyline.strokeColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
                                                                     
                                                                     NSString * condition = [obj getValueFromKey:@"tinh_trang_id"];
                                                                     
                                                                     [polyline setFillColor:[condition isEqualToString:@"1"] ? [UIColor colorWithRed:0 green:255 blue:0 alpha:0.8] : [condition isEqualToString:@"2"] ? [UIColor colorWithRed:255 green:0 blue:0 alpha:0.8] : [UIColor colorWithRed:0 green:0 blue:255 alpha:0.8]];
                                                                     
                                                                     polyline.zIndex = -1;
                                                                     
                                                                     polyline.map = mapView;
                                                                     
                                                                     [dataPoly addObject:polyline];
                                                                 }

                                                         }
                                                     }];
    }
    else
    {
        [self clearPolygon];
    }
}

- (void)clearPolygon
{
    for(GMSPolygon __strong * path in dataPoly)
    {
        path.map = nil;
        
        path = nil;
    }
    
    [dataPoly removeAllObjects];
}

- (void)didRequestArea:(float)lat andLng:(float)lng
{
    [renderer clear];
    
    
    
    [[LTRequest sharedInstance] didRequestInfo:@{@"absoluteLink":[NSString stringWithFormat:@"http://45.117.169.237/gami/lo/info?lon=%f&lat=%f", lng, lat],
                                                 @"method":@"GET",
                                                 @"overrideAlert":@(1)
                                                 } withCache:^(NSString *cacheString) {
                                                     
                                                 } andCompletion:^(NSString *responseString, NSString *errorCode, NSError *error, BOOL isValidated) {
                                                     
                                                     [indicator stopAnimating];

                                                     [renderer clear];
                                                     
                                                     polyMarker.map = nil;
                                                     
                                                     if([errorCode isEqualToString:@"200"])
                                                     {
                                                         [self didRequestPositionInfo:[responseString objectFromJSONString][@"gid"] andLat:lat andLng:lng];
                                                         
                                                         [[[EM_MenuView alloc] initWithPop:[responseString objectFromJSONString]] showWithCompletion:^(int index, id object, EM_MenuView *menu) {
 
                                                             if(object)
                                                             {
                                                                 AP_Information_ViewController * info = [AP_Information_ViewController new];
                                                                 
                                                                 info.info = object;
                                                                 
                                                                 [menu close];
                                                                 
                                                                 [self.navigationController pushViewController:info animated:YES];
                                                             }
                                                         }];
                                                     }
                                                     else if([errorCode isEqualToString:@"204"])
                                                     {
                                                         
                                                     }
                                                     else
                                                     {
                                                         [self showToast:@"Lô bạn vừa chạm chưa có thông tin. Mời thử lại sau." andPos:0];
                                                         
                                                         [renderer clear];
                                                     }
                                                     
                                                     if(!responseString)
                                                     {
                                                         [renderer clear];
                                                     }
                                                 }];
}

- (void)prefixRequest
{
    [self didGotoPosition:[@"13.9241" floatValue] andLong:[@"108.9209" floatValue] andZoom:19];
}

- (void)didChangeAngle:(float)heading
{
    NSString *geoDirectionString = [[NSString alloc] init];
    if(heading >=337.5 || heading <= 22.5){
        geoDirectionString = sign[0]; //@"1"; //Bắc
    } else if(heading >22.5 && heading <= 67.5){
        geoDirectionString = sign[1]; //@"6";    // Đông Bắc
    } else if(heading >67.5 && heading <= 112.5){
        geoDirectionString = sign[2]; //@"7";    //Đông
    } else if(heading >112.5 && heading <= 157.5){
        geoDirectionString = sign[3]; //@"4";   //Đông Nam
    } else if(heading >157.5 && heading <= 202.5){
        geoDirectionString = sign[4]; // @"5";   //Nam
    } else if(heading >202.5 && heading <= 247.5){
        geoDirectionString = sign[5]; // @"3";  // Tây Nam
    } else if(heading >248 && heading <= 293){
        geoDirectionString = sign[6]; // @"0";  //Tây
    } else if(heading >247.5 && heading <= 337.5){
        geoDirectionString = sign[7]; // @"2"; //Tây Bắc
    }
    
    mainMarker.icon = [UIImage imageNamed:@"check"]; //imageNamed:[[self getObject:@"setting"][@"show"] boolValue] ? geoDirectionString : @"blue"];
}

- (float)lat
{
    return  [[[Permission shareInstance] currentLocation][@"lat"] floatValue];
}

- (float)lng
{
    return [[[Permission shareInstance] currentLocation][@"lng"] floatValue];
}

- (void)currentMaker:(float)lat andLong:(float)lng
{
    mainMarker = [[GMSMarker alloc] init];
    mainMarker.position = CLLocationCoordinate2DMake(lat, lng);
    mainMarker.icon = [UIImage imageNamed:@"check"];
    mainMarker.map = mapView;
}

- (void)layerMarker:(float)lat andLong:(float)lng andInfo:(NSDictionary*)info
{
    if(layerMarker)
    {
        layerMarker.map = nil;
        
        layerMarker = nil;
    }
    
    layerMarker = [[GMSMarker alloc] init];
    layerMarker.accessibilityLabel = [info bv_jsonStringWithPrettyPrint:YES];
    layerMarker.position = CLLocationCoordinate2DMake(lat, lng);
    layerMarker.title = @"";
    layerMarker.snippet = @"";
    layerMarker.map = mapView;
    
    mapView.selectedMarker = nil;
}

- (void)searchMaker:(float)lat andLong:(float)lng andInfo:(NSDictionary*)info
{
    if(searchMarker)
    {
        searchMarker.map = nil;
        
        searchMarker = nil;
    }
    
    searchMarker = [[GMSMarker alloc] init];
    searchMarker.accessibilityLabel = [info bv_jsonStringWithPrettyPrint:YES];
    searchMarker.position = CLLocationCoordinate2DMake(lat, lng);
    searchMarker.icon = [GMSMarker markerImageWithColor:[UIColor colorWithRed:255 green:255 blue:0 alpha:1]];
    searchMarker.title = @"";
    searchMarker.snippet = @"";
    searchMarker.map = mapView;
}

- (UIToolbar*)toolBar
{
    UIToolbar * toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, screenWidth1, 50)];

    toolBar.barStyle = 0;
    
    toolBar.items = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle:[[self getValue:@"lang"] isEqualToString:@"vi"] ? @"Thoát" : @"Done" style:UIBarButtonItemStyleDone target:self action:@selector(didPressDone)]
    ];
    
    return toolBar;
}
           
- (void)didPressDone
{
    [self.view endEditing:YES];
}

- (void)focusMapToShowAllMarkers
{
    [self didGotoPosition:15.875368 andLong:108.339284 andZoom:17];
}

- (IBAction)didPressMap:(UIButton*)sender
{
    [self focusMapToShowAllMarkers];
}

- (IBAction)didPressDismiss:(UIButton*)sender
{
    bar.hidden = YES;
    
    [self.view endEditing:YES];
}

- (IBAction)didPressLocation:(UIButton*)sender
{
    mainMarker.position = CLLocationCoordinate2DMake([self lat], [self lng]);
    
    [self didGotoPosition:[self lat] andLong:[self lng] andZoom:15];
}

- (IBAction)didPressMapLayer:(UIButton*)sender
{
    [self prefixRequest];
}

- (IBAction)didPressMapChange:(UIButton*)sender
{
    [[Permission shareInstance] askCamera:^(CamPermisionType type) {
        
        switch (type) {
            case authorized:
            case per_granted:
                [self didShowQR];
                break;
            case denied:
            case per_denied:
            case restricted:
            [self showToast:@"Bạn cần bật truy cập Camera để dùng chức năng này" andPos:0];
                break;
            default:
                break;
        }
        
    }];
}

- (IBAction)didPressMapType:(UIButton*)sender
{
    [self.navigationController pushViewController:[AP_Web_List_ViewController new] animated:YES];
}

- (IBAction)didPressSearch:(UIButton*)sender
{
    [search becomeFirstResponder];
}

- (void)hideShowSearch:(BOOL)isShow
{
    [UIView animateWithDuration:0.3 animations:^{
        
        top.alpha = isShow;
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)didShowDate
{
    NSDictionary * dict = nil;
    
    if([self getObject:@"setting"])
    {
        dict = [self getObject:@"setting"];
    }
    else
    {
        dict = @{@"date":[[NSDate date] stringWithFormat:@"dd/MM/yyyy"], @"gender":@"0", @"show":@"0"};
    }
    
    [[[EM_MenuView alloc] initWithDate:@{@"date":dict[@"date"], @"gender":dict[@"gender"], @"show":dict[@"show"]}] showWithCompletion:^(int index, id object, EM_MenuView *menu) {
        
        if(object)
        {
            NSMutableDictionary * data = [@{@"date":object[@"date"], @"gender":object[@"gender"], @"show":dict[@"show"]}  mutableCopy];
            
            if(!isShow)
            {
                [changeMap setImage:[UIImage imageNamed:@"ic_off_compass_zodiac"] forState:UIControlStateNormal];
                
                data[@"show"] = @"1";
            }
            else
            {
                //data[@"show"] = [data[@"show"] boolValue] ? @"0": @"1";
            }
            
            [self addObject:data andKey:@"setting"];
            
            if([data[@"show"] boolValue])
            {
                [self clearPolygon];
            }
            else
            {
                [self didRequestForAreaInfo];
            }
            
            isShow = [self getObject:@"setting"];
            
            [self didSetDate:[self getDateFromDateString:object[@"date"]] andGender:object[@"gender"]];
            
            [[Permission shareInstance].locationManager stopUpdatingHeading];
            
            [[Permission shareInstance].locationManager startUpdatingHeading];
        }
    }];
}

- (void)didPressDate
{
    NSDictionary * dict = nil;
    
    if([self getObject:@"setting"])
    {
        dict = [self getObject:@"setting"];
    }
    else
    {
        dict = @{@"date":[[NSDate date] stringWithFormat:@"dd/MM/yyyy"], @"gender":@"0", @"show":@"0"};
    }
    
    [[[EM_MenuView alloc] initWithDate:@{@"date":dict[@"date"], @"gender":dict[@"gender"], @"show":dict[@"show"]}] showWithCompletion:^(int index, id object, EM_MenuView *menu) {
        
        if(object)
        {
            NSMutableDictionary * data = [@{@"date":object[@"date"], @"gender":object[@"gender"], @"show":dict[@"show"]}  mutableCopy];
            
            [self addObject:data andKey:@"setting"];
            
            isShow = [self getObject:@"setting"];
            
            [self didSetDate:[self getDateFromDateString:object[@"date"]] andGender:object[@"gender"]];
            
            [[Permission shareInstance].locationManager stopUpdatingHeading];
            
            [[Permission shareInstance].locationManager startUpdatingHeading];
        }
    }];
}

- (void)didSetDate:(NSDate*)date andGender:(NSString*)gender
{
    NSString *tempDigit = [date stringWithFormat:@"yyyy"] ;
    NSMutableArray *tempArray = [NSMutableArray array];
    [tempDigit enumerateSubstringsInRange:[tempDigit rangeOfString:tempDigit]
                                  options:NSStringEnumerationByComposedCharacterSequences
                               usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                   [tempArray addObject:substring] ;
                               }] ;
    int sum = 0;
    
    for (NSString *string in tempArray)
    {
        sum += [string integerValue];
    }
    
    [self sign:sum % 9 andGender:gender];
}

- (void)sign:(int)numb andGender:(NSString*)gender
{
    // 0 : ngũ quỷ,
    
    // 1 : phục vị
    
    // 2 : lục sát
    
    // 3 : tuyệt maạng
    
    // 4 : họa hại
    
    //5 : sanh khí
    
    // 6: phước đức
    
    // 7: thiện y
    
    NSArray * signsMale = @[@[@"3", @"5", @"4", @"0", @"2", @"1", @"7", @"6"], // khôn
                        @[@"1", @"0", @"7", @"5", @"6", @"3", @"4", @"2"], //khảm
                        @[@"6", @"4", @"5", @"7", @"1", @"2", @"0", @"3"], //ly
                        @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7"], //cấn
                        @[@"4", @"6", @"3", @"2", @"0", @"7", @"1", @"5"], //đối
                        @[@"2", @"7", @"0", @"4", @"3", @"6", @"5", @"1"], //càn
                        @[@"3", @"5", @"4", @"0", @"2", @"1", @"7", @"6"], //khôn
                        @[@"5", @"3", @"6", @"1", @"7", @"0", @"2", @"4"], //tốn
                        @[@"7", @"2", @"1", @"6", @"5", @"4", @"3", @"0"] //chấn
                        ];

    NSArray * signsFemale = @[@[@"5", @"3", @"6", @"1", @"7", @"0", @"2", @"4"],
                              @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7"],
                              @[@"2", @"7", @"0", @"4", @"3", @"6", @"5", @"1"],
                              @[@"4", @"6", @"3", @"2", @"0", @"7", @"1", @"5"],
                              @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7"],
                              @[@"6", @"4", @"5", @"7", @"1", @"2", @"0", @"3"],
                              @[@"1", @"0", @"7", @"5", @"6", @"3", @"4", @"2"],
                              @[@"3", @"5", @"4", @"0", @"2", @"1", @"7", @"6"],
                              @[@"7", @"2", @"1", @"6", @"5", @"4", @"3", @"0"]
                              ];
                             
    sign = [gender isEqualToString:@"0"] ? signsMale[numb] : signsFemale[numb];
}

- (void)didRequestForPoints
{
    [[LTRequest sharedInstance] didRequestInfo:@{@"CMD_CODE":@"point/list",
                                                 @"method":@"GET",
                                                 @"overrideLoading":@(1),
                                                 @"host":self,
                                                 @"overrideAlert":@(1)
                                                 } withCache:^(NSString *cacheString) {
                                                     
                                                 } andCompletion:^(NSString *responseString, NSString *errorCode, NSError *error, BOOL isValidated) {
                                                     
                                                     if(![errorCode isEqualToString:@"200"])
                                                     {
                                                         [self showToast:@"Lỗi xảy ra, mời bạn thử lại sau" andPos:0];
                                                         
                                                         return ;
                                                     }
//
//                                                     [dataList removeAllObjects];
//
//                                                     [dataList addObjectsFromArray:[responseString objectFromJSONString][@"array"]];
//
//                                                     [self didLayoutPoints];
                                                 }];
}

- (void)didLayoutPoints
{
//    for(NSDictionary * dict in dataList)
//    {
//        NSArray * array = dict[@"geometry"][@"coordinates"];
//        GMSMarker *marker = [[GMSMarker alloc] init];
//        marker.position = CLLocationCoordinate2DMake([array[1] floatValue], [array[0] floatValue]);
//        marker.map = mapView;
//        marker.icon = [UIImage imageNamed:@"trans"];
//        [markerList addObject:marker];
//        marker.accessibilityLabel = [dict[@"properties"] bv_jsonStringWithPrettyPrint:YES];
//    }
    
    [self didAddLayerTile];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [[E_Overlay_Menu shareMenu] didShowSearch:@{@"host":self, @"textField":search/*, @"clearText":@(0)*/} andCompletion:^(NSDictionary *actionInfo) {
                
        if([actionInfo responseForKey:@"state"])
        {
            [menuMap setEnabled:![actionInfo[@"state"] boolValue]];
        }
        else
        {
            NSLog(@"%@", actionInfo[@"char"]);
            
            AP_Detail_ViewController * detail = [AP_Detail_ViewController new];

            detail.detail = actionInfo[@"char"];

            [self.navigationController pushViewController:detail animated:YES];
            
//            NSDictionary * searchInfo = actionInfo[@"char"];
//            
//            if([searchInfo[@"type"] isEqualToString:@"point"])
//            {
//                [self searchMaker:[searchInfo[@"lat"] floatValue] + 0 andLong:[searchInfo[@"lng"] floatValue] andInfo:searchInfo];
//                
//                [self didGotoPosition:[searchInfo[@"lat"] floatValue] andLong:[searchInfo[@"lng"] floatValue] andZoom:15];
//            }
//            else
//            {
//                [self didRequestArea:[searchInfo[@"lat"] floatValue] andLng:[searchInfo[@"lng"] floatValue]];
//            }
        }
        
     }];
}

//- (IBAction)didShowQR
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.navigationController pushViewController:[AP_QR_ViewController new] animated:YES];
//    });
//}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [[E_Overlay_Menu shareMenu] endTimer];
    
    return YES;
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker;
{
    AP_Web_ViewController * web = [AP_Web_ViewController new];
    
    web.info = [[marker.accessibilityLabel objectFromJSONString] reFormat];
    
    [self.navigationController pushViewController:web animated:YES];
}

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    mainMarker.position = coordinate;
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
//    [self.navigationController pushViewController:[AP_Detail_ViewController new] animated:YES];

//    [self didShowQR];
    
    return;
    
    CGPoint locationInView = [mapView.projection pointForCoordinate:coordinate];
    
    NSLog(@"%f - %f", coordinate.latitude, coordinate.longitude);
    
    //if(mapView.camera.zoom >= 18)
    {
        indicator.frame = CGRectMake(locationInView.x, locationInView.y, 20, 20);

        [indicator startAnimating];
    }
    
//    if (GMSGeometryContainsLocation(coordinate, renderer.polyTemp.path , YES))
//    {
//        mapView.selectedMarker = polyMarker;
//    }
//    else
    {
        [self didRequestArea:coordinate.latitude andLng:coordinate.longitude];
    }
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position
{
    if(mapView.camera.zoom >= 18)
    {
//        if([[self getObject:@"setting"][@"show"] boolValue])
//        {
//            return;
//        }
//
//        [self showSVHUD:@"Đang tải" andOption:0];
//
//        [self getAreaInfo];
    }
    else
    {
       // [self clearPolygon];
    }
}

- (void)mapView:(GMSMapView *)mapView didTapOverlay:(GMSOverlay *)overlay
{
//    NSDictionary * overLayInfo = [overlay.accessibilityLabel objectFromJSONString];
    
//    NSLog(@"%@", overLayInfo);
    
    [self stopTracking];

//    for(GMSPolyline * polyme in polyList)
//    {
        if([overlay.accessibilityValue isEqualToString:@"1"])
        {
            ((GMSPolyline*)overlay).strokeColor = [UIColor orangeColor];

            overlay.accessibilityValue = @"0";

            return;
        }

        for(GMSPolyline * line in polyList)
        {
            line.strokeColor = [UIColor orangeColor];

            line.accessibilityValue = @"0";
        }

        ((GMSPolyline*)overlay).strokeColor = [UIColor blueColor];

        overlay.accessibilityValue = @"1";

        [self tracking];
//    }
}

- (nullable UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker
{
    if(marker == mainMarker)
    {
        return nil;
    }
    
    for(GMSMarker * marker in markerList)
    {
        marker.icon = [UIImage imageNamed:@"trans"];//[GMSMarker markerImageWithColor:[UIColor clearColor]];
    }
    
//    marker.icon = [UIImage imageNamed:@"trans"];//[GMSMarker markerImageWithColor:[UIColor clearColor]];
    
    NSMutableDictionary * markerInfo1 = [[marker.accessibilityLabel objectFromJSONString] reFormat];

//    [[[EM_MenuView alloc] initWithPop:markerInfo1] showWithCompletion:^(int index, id object, EM_MenuView *menu) {
//        if (object) {
//            AP_Information_ViewController * info = [AP_Information_ViewController new];
//
//            info.info = object;
//
//            [menu close];
//
//            [self.navigationController pushViewController:info animated:YES];
//        }
//    }];
    
    return nil;
    
    NSMutableDictionary * markerInfo = [[marker.accessibilityLabel objectFromJSONString] reFormat];
    
    int indexing = 1;
    
    if([markerInfo responseForKey:@"images"] && ![markerInfo[@"images"] isKindOfClass:[NSString class]])
    {
        indexing = 0;
        
        if([markerInfo[@"images"] isKindOfClass:[NSArray class]] && ((NSArray*)markerInfo[@"images"]).count == 0)
        {
            indexing = 1;
        }
    }
    
    UIView * view = [[NSBundle mainBundle] loadNibNamed:@"Annotation" owner:nil options:nil][indexing];
    
    ((UIView*)[self withView:view tag:15]).transform = CGAffineTransformMakeRotation(150);
    
    UILabel * des = ((UILabel*)[self withView:view tag:12]);
    
    if(marker == polyMarker)
    {
        ((UILabel*)[self withView:view tag:10]).text = [NSString stringWithFormat:@"Lô: %@", [markerInfo getValueFromKey:@"ten_lo"]];

        NSString * condition = [markerInfo getValueFromKey:@"tinh_trang_id"];
        
        [((UILabel*)[self withView:view tag:10]) setTextColor:[condition isEqualToString:@"1"] ? [UIColor colorWithRed:0 green:255 blue:0 alpha:0.8] : [condition isEqualToString:@"2"] ? [UIColor colorWithRed:255 green:0 blue:0 alpha:0.8] : [UIColor colorWithRed:0 green:0 blue:255 alpha:0.8]];
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Mã lô: %@ \nTrạng thái: %@ \nDiện tích: %@ m2 \n%@", [markerInfo getValueFromKey:@"ki_hieu"], [self status:[markerInfo getValueFromKey:@"tinh_trang_id"]][@"status"], [markerInfo getValueFromKey:@"dien_tich"], [markerInfo getValueFromKey:@"description"]]];
        
        [string setColorForText:[self status:[markerInfo getValueFromKey:@"tinh_trang_id"]][@"status"] withColor:[self status:[markerInfo getValueFromKey:@"tinh_trang_id"]][@"color"]];
        
        des.attributedText = string;
    }
    else if(marker == searchMarker)
    {
        ((UILabel*)[self withView:view tag:10]).text = [NSString stringWithFormat:@"%@", [markerInfo getValueFromKey:@"text"]];
        
//        [(UIImageView*)[self withView:view tag:11] imageUrl:[markerInfo[@"images"] firstObject]];

        des.text = [markerInfo getValueFromKey:@"description"];
    }
    else
    {
        ((UILabel*)[self withView:view tag:10]).text = [NSString stringWithFormat:@"%@", [markerInfo getValueFromKey:@"name"]];
        
//        [(UIImageView*)[self withView:view tag:11] imageUrl:[markerInfo[@"images"] firstObject]];

        des.text = [markerInfo getValueFromKey:@"description"];
    }
    
    marker.tracksInfoWindowChanges = YES;

    float height = [des sizeOfMultiLineLabel].height;
    
    [view setHeight:height + (indexing ? 95 : 250) animated:NO];
    
    if(indexing == 0)
    {
        [view setWidth:230 animated:NO];
    }

    if(indexing == 0)
        [(UIImageView*)[self withView:view tag:100] imageUrl:[markerInfo[@"images"] firstObject][@"image_path"]];
    
    return view;
}

- (NSDictionary*)status:(NSString*)statusId
{
    return @{@"color":[statusId isEqualToString:@"1"] ? [UIColor colorWithRed:0 green:255 blue:0 alpha:0.8] : [statusId isEqualToString:@"2"] ? [UIColor colorWithRed:255 green:0 blue:0 alpha:0.8] : [UIColor colorWithRed:0 green:0 blue:255 alpha:0.8], @"status":[statusId isEqualToString:@"1"] ? @"Chưa bán" : [statusId isEqualToString:@"2"] ? @"Đã bán" : @"Đã đặt cọc"};
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
