/*
 * 下载见PersonsTableViewController
 */
#import "AddPersonViewController.h"

@interface AddPersonViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *ageField;
@end

@implementation AddPersonViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem.title = @"添加";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.nameField setDelegate:self];
    [self.ageField setDelegate:self];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"隐藏键盘啊！！！");
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)addPersonWithJsonRequest:(UIButton *)sender
{
    NSString *name = self.nameField.text;
    NSString *age = self.ageField.text;
    
    NSLog(@"添加person 姓名：%@ 年龄 %@", name, age);
    NSString *addPersonJsonURLString = @"http://192.168.1.148:8080/new_person";

    // 0
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    // 1
    NSURL *url = [NSURL URLWithString:addPersonJsonURLString];
    
    // 2
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField: @"Content-Type"];
    
    // 3
    NSDictionary *dictionary = @{@"name": name,
                                 @"age": [NSNumber numberWithInteger:[age intValue]]};
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:kNilOptions error:&error];
    NSLog(@"Data: %@", data);
    
    if (!error) {
        // 4
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                   fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
                                                                       // Handle response here
                                                                   }];
        
        // 5
        [uploadTask resume];
    }
}
- (IBAction)addPersonWithTextRequest:(UIButton *)sender
{
    NSString *name = self.nameField.text;
    NSString *age = self.ageField.text;
    
    NSLog(@"添加person 姓名：%@ 年龄 %@", name, age);
    NSString *addPersonJsonURLString = @"http://192.168.1.148:8080/new_person";

    // 0
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    // 1
    NSURL *url = [NSURL URLWithString:addPersonJsonURLString];

    // 2
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"text/plain" forHTTPHeaderField: @"Content-Type"];
    
    // 3
    NSError *error = nil;
    NSString* str = [NSString stringWithFormat:@"name=%@&age=%@", name, age];
    NSLog(@"请求字符串: %@", str);
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    if (!error) {
        // 4
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                   fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
                                                                       // Handle response here
                                                                   }];
        
        // 5
        [uploadTask resume];
    }
}

@end
