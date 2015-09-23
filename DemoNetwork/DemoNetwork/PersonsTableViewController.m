/*
 * 用来演示调用最高层的NSURLSession来达到下载数据的目的
 * 测试服务器在Erlang/SimpleMobileBackend
 * 请求地址：http://192.168.1.148:8080/all_persons.json
 * 上传任务见AddPersonViewController
 */
#import "PersonsTableViewController.h"

@interface PersonsTableViewController ()

@property (nonatomic) NSURLSession *session;
@property (nonatomic, copy) NSArray *persons; // 下载存所有person数据，用表格显示

@end

@implementation PersonsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.tabBarItem.title = @"persons";
        
        // 第0步，初始化一个session
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config
                                                 delegate:nil
                                            delegateQueue:nil];
    }
    return self;
}

/****** 基本的表格的部分 ***********/
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"UITableViewCell"];
    
    // 添加pull to refresh的功能
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(myLoadDataForPullToRefresh)  // 设置下拉刷新回调函数
                  forControlEvents:UIControlEventValueChanged];
}

// 1, 下拉刷新时候的回调函数
- (void)myLoadDataForPullToRefresh
{
    NSLog(@"加载新数据...");
    [self loadData];
}

- (void)loadData
{
    NSLog(@"DataManager通过网络加载数据中...");
    // 发送请求几大步
    // 第一步，构建NSURL
    NSString *requestString = @"http://192.168.1.148:8080/all_persons.json";
    NSURL *url = [NSURL URLWithString:requestString];
    
    // 第二补，构建NSURLRequest
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    NSLog(@"REQ: %@", req);
    
    // 第三步，构建NSURLSessionDataTask
    NSURLSessionDataTask *dataTask =
    [self.session dataTaskWithRequest:req
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        NSLog(@"网络下载结束，更新列表");
                        NSLog(@"response: %@", response);
                        // 实际的第五步，下载成功之后的回调
                        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        NSLog(@"json: %@", jsonString);
                        
                        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                   options:0
                                                                                     error:nil];
                        NSLog(@"下载到的json数据：%@", jsonObject);
                        self.persons = jsonObject[@"persons"];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self dataDidLoad]; // 主线程去调用更新table view的函数
                        });
                    }];
    
    // 第四步，启动任务
    [dataTask resume];
}

- (void)dataDidLoad
{
    NSLog(@"最终，加载完毕，更新表格...");
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

#pragma mark - Table view data source 每行显示人名年龄
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    NSInteger num = [self.persons count];
    NSLog(@"列表行数: %d", (int)num);
    return num;
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"
                                                            forIndexPath:indexPath];
    NSDictionary *person = self.persons[indexPath.row];
    NSString *cellText = [NSString stringWithFormat:@"姓名：%@ ----- 年龄 %@", person[@"name"], person[@"age"]];
    cell.textLabel.text = cellText;
    return cell;
}

@end
