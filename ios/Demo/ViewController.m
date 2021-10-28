//
//  ViewController.m
//  Demo
//
//  Created by EM on 2021/6/25.
//

#import "ViewController.h"
#import <ZHDebugPanel/ZHDPManager.h>

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,retain) NSArray *items;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"示例";
    
    [self.navigationController setNavigationBarHidden:NO];
//    self.navigationController.navigationBar.translucent = YES;

    if (@available(iOS 11.0, *)){
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    }else{
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];

    [self loadData];
    [self.tableView reloadData];
}
- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)loadData{
    __weak __typeof__(self) weakSelf = self;
    self.items = @[
        @{
            @"title": @"调试控制台",
            @"block": ^(void){
                [ZHDPMg() open];
            }
        },
        @{
            @"title": @"移除 调试控制台",
            @"block": ^(void){
                [ZHDPMg() close];
            }
        },
        @{
            @"title": @"发起请求",
            @"block": ^(void){
                [weakSelf testRequest];
            }
        }
    ];
}

- (void)testRequest{
    
    /*
     
     [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:nil]
     
     
     - (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:
     不注册 [NSURLProtocol registerClass   系统默认处理
     */
    
    NSDictionary *parameters = @{
      };
    NSString *aURLString = @"https://dataapineice.1234567.com.cn/dataapi/fund/fundbaseinfos";
    aURLString = @"https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec";
    NSURL *aURL = [NSURL URLWithString:aURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aURL
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30];
    [request setHTTPMethod:@"GET"];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
//        NSData *data = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
//        if (data) [request setHTTPBody:data];
    
    
//    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"--------------------");
        NSLog(@"%@",result);
        NSLog(@"--------------------");
    }];
    [dataTask resume];
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.items.count;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellID = @"BaseCellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        if (@available(iOS 14.0, *)) {
            cell.backgroundConfiguration = [UIBackgroundConfiguration clearConfiguration];
        }
    }
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.text = self.items[indexPath.row][@"title"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    void (^block) (void) = self.items[indexPath.row][@"block"];
    if (block) {
        block();
    }
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        if (@available(iOS 15.0, *)){
            _tableView.sectionHeaderTopPadding = 0;
        }
        
        _tableView.directionalLockEnabled = YES;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    return _tableView;
}



@end
