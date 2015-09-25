/*
 * 根据6.2课程，学习CFNetwork来做Socket编程
 * 服务器用的是Erlang/TcpServer做服务器端，就是一个echo服务器，把收来的消息简单的回送回去
 */

#import "SocketViewController.h"

#import <netinet/in.h>
#include <arpa/inet.h>
#import <CFNetwork/CFNetwork.h>

@interface SocketViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *serverIpField;
@property (weak, nonatomic) IBOutlet UITextField *serverPortField;
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendDataButton;
@property (weak, nonatomic) IBOutlet UITextView *outputTextArea;

@property (nonatomic) CFSocketRef socket;

// 为了在C函数当中调用，声明这些函数
- (void)enableSendDataButton;
- (void)appendNewSocketData:(NSString *)newData;

@end

#pragma mark - C语言函数，定义在类外面
// C Functions
void socketCallBackFun(CFSocketRef inSocketRef,
                       CFSocketCallBackType inCallbackType,
                       CFDataRef inAddress,
                       const void *inData,
                       void *inUserInfo)
{
    // get 'self'
    SocketViewController *self = (__bridge SocketViewController *)inUserInfo;
    if (inCallbackType == kCFSocketConnectCallBack) {
        // connection setup callback
        [self enableSendDataButton];
    } else if (inCallbackType == kCFSocketDataCallBack) {
        // receive data
        NSLog(@"Data is on socket");
        
        //Control reaches here when there is a chunk of data to read
        CFDataRef dataRef = (CFDataRef) inData;
        int len = CFDataGetLength(dataRef);
        CFRange range = CFRangeMake(0, len);
        UInt8 buffer[len+1];
        if(len <= 0) {
            NSLog(@"No data read");
            return;
        }
        memset((void*)buffer, 0, sizeof(buffer));
        CFDataGetBytes(dataRef, range, buffer);
        NSString *byteString = [[NSString alloc] initWithBytes:buffer
                                                        length:len
                                                      encoding:NSUTF8StringEncoding];
        NSString *byteStringWithNewLine = [byteString stringByAppendingString:@"\n"];
        [self appendNewSocketData:byteStringWithNewLine];
    }
}


@implementation SocketViewController

#pragma mark - 连接服务器
- (IBAction)openSocketToServer:(UIButton *)sender
{
    struct sockaddr_in finalSocketInfo;
    // 192.168.1.148:8888
    const char *serverIpAddress = [self.serverIpField.text UTF8String];
    int serverPort = [self.serverPortField.text intValue];
    
    // My Mac's IP address
    memset(&finalSocketInfo, 0, sizeof(finalSocketInfo));
    inet_pton(AF_INET, serverIpAddress, &finalSocketInfo.sin_addr);
    finalSocketInfo.sin_family = AF_INET;
    finalSocketInfo.sin_port = htons(serverPort); // Host order TO Network order Short
    
    // Create CFDataRef for host, where to connect
    CFDataRef host = CFDataCreate(NULL, (unsigned char *)&finalSocketInfo, sizeof(finalSocketInfo));
    
    // pass 'self' to C function to be able to callback
    CFSocketContext ctx = {0, (__bridge void *)self, NULL, NULL, NULL};
    
    // Create a socket which is used to connect to the server
    CFOptionFlags callbackFlags = kCFSocketConnectCallBack | kCFSocketDataCallBack;

    // 根据Apple的CFNetworking Guide里边socket编程3大步
    // 1, 创建socket，指定回调函数
    self.socket = CFSocketCreate(NULL, PF_INET, SOCK_STREAM, IPPROTO_TCP, callbackFlags,
                                 (CFSocketCallBack)&socketCallBackFun, &ctx);
    // 2, 创建run loop source
    // 把socket添加到run loop里，应该就能够激活我指定的回调事件发生时候的回调了
    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(NULL, self.socket, 0);
    // 3, 添加到run loop当中，这样，socket收到消息之后就能回调了
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
    
    // Now connect to server
    CFSocketError error = CFSocketConnectToAddress(self.socket, host, 10);
    
    if (error != kCFSocketSuccess) {
        NSLog(@"Error connect to address!");
    }
    
    // Release
    CFRelease(source);
    CFRelease(host);
}

#pragma mark - 断开服务器
- (IBAction)closeSocketToServer:(UIButton *)sender
{
    [self disableSendDataButton];
    // invalidate the socket to "close" it
    CFSocketInvalidate(self.socket);
    CFRelease(self.socket);
    self.socket = nil;
}

#pragma mark - 发送数据
- (IBAction)sendData:(id)sender
{
    if (CFSocketIsValid(self.socket)) {
        NSData *data = [self.inputTextField.text dataUsingEncoding:NSUTF8StringEncoding];
        // 第二个参数是发送到的地址，对于UDP才有用，因为UDP不是连接先的
        CFSocketSendData(self.socket, NULL, (__bridge CFDataRef)data, 100);
    }
}

- (void)appendNewSocketData:(NSString *)newData
{
    self.outputTextArea.text = [self.outputTextArea.text stringByAppendingString:newData];
    [self scrollToBottom];
}

-(void) scrollToBottom {
    [self.outputTextArea scrollRangeToVisible:NSMakeRange([self.outputTextArea.text length], 0)];
    [self.outputTextArea setScrollEnabled:NO];
    [self.outputTextArea setScrollEnabled:YES];
}

#pragma mark - 根据服务器连接状态改变按钮状态
- (void)enableSendDataButton
{
    NSLog(@"连接好server之后，激活发送按钮");
    self.sendDataButton.enabled = YES;
}

- (void)disableSendDataButton
{
    NSLog(@"在没有连接好server之前，先禁止发送按钮");
    self.sendDataButton.enabled = NO;
}

#pragma mark - 常规函数
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem.title = @"socket";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.inputTextField setDelegate:self];
    [self disableSendDataButton];
    
    [self.sendDataButton setTitle:@"send" forState:UIControlStateNormal];
    [self.sendDataButton setTitle:@"XXXX" forState:UIControlStateDisabled];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
