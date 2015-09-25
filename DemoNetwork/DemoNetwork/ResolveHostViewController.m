/*
 * 6.1 解析域名到IP地址
 * 不需要本地任何服务器，就仅仅演示了如何使用基本的CFNetwork的API
 * 以及一些bridge转换的过程
 */
#import "ResolveHostViewController.h"

#import <netinet/in.h>
#include <arpa/inet.h>
#import <CFNetwork/CFNetwork.h>

@interface ResolveHostViewController ()
@property (weak, nonatomic) IBOutlet UITextField *hostnameField;

@property (weak, nonatomic) IBOutlet UILabel *ipAddressLabel;
@end

// 纯C语言的函数，写在类定义的外面
void resolveCallBackFun(CFHostRef inHostInfo,
                        CFHostInfoType inType,
                        const CFStreamError *inError,
                        void *inUserInfo)
{
    if (inError->error == noErr) {
        NSArray *addresses = (__bridge NSArray *)(CFHostGetAddressing(inHostInfo, NULL));
        CFDataRef address = (__bridge CFDataRef)(addresses[0]); // 就取第一个出来
        struct sockaddr_in *addr = (struct sockaddr_in *)CFDataGetBytePtr(address);
        
        NSString *ipStr = [NSString stringWithUTF8String:(char *)inet_ntoa(addr->sin_addr)];
        
        // 转换成类对象，然后回调回Objective-C的部分去
        ResolveHostViewController *self = (__bridge ResolveHostViewController *)inUserInfo;
        [self.ipAddressLabel setText:ipStr];
    } else {
        NSLog(@"something wrong!");
    }
}

@implementation ResolveHostViewController
// 解析hostname到IP地址
- (IBAction)resolveIpAddress:(UIButton *)sender
{
    NSLog(@"解析DNS...");
    NSString *hostname = self.hostnameField.text;
    CFHostRef hostRef = CFHostCreateWithName(NULL, (__bridge CFStringRef)(hostname));
    
    // 演示如何把对象self传入给一个普通的C函数，然后让其回调对象中的属性
    CFHostClientContext ctx = {0, (__bridge void *)self, NULL, NULL, NULL};

    // 因为是C语言级别的API，只能函数指针方式回调
    CFHostSetClient(hostRef, (CFHostClientCallBack)&resolveCallBackFun, &ctx);
    CFHostScheduleWithRunLoop(hostRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFStreamError error = {0, 0};
    CFHostStartInfoResolution(hostRef, kCFHostAddresses, &error);
    [self.ipAddressLabel setText:@"resolving..."];
    
    // create的，要手动release掉
    CFRelease(hostRef);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem.title = @"解析Host";
    }
    return self;
}

@end
