/*
 * 根据6.3课程，学习CFStream来做Socket的Stream编程
 * 服务器也是用的Erlang/TcpServer做服务器端，就是一个echo服务器，把收来的消息简单的回送回去
 */

#import "StreamViewController.h"

@interface StreamViewController ()
{
    UInt8 buffer[1024];
}

@property (nonatomic) CFWriteStreamRef writeStreamRef;
@property (nonatomic) CFReadStreamRef  readStreamRef;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (weak, nonatomic) IBOutlet UITextField *serverHostField;
@property (weak, nonatomic) IBOutlet UITextField *serverPortField;

@property (weak, nonatomic) IBOutlet UITextField *dataField;
@property (weak, nonatomic) IBOutlet UITextView *outputTextArea;

// For C callback functions
- (void)closeWriteStream;
- (void)readDataFromServer;

@end

#pragma mark - C函数部分
char buffer[1024];

void writeStreamCallBackFun(CFWriteStreamRef stream, CFStreamEventType type, void * userInfo)
{
    StreamViewController *self = (__bridge StreamViewController *)userInfo;
    
    if (type == kCFStreamEventOpenCompleted) {
        NSLog(@"成功打开到Server的stream");
        [self.statusLabel setText:@"status: 成功连接"];
    } else if (type == kCFStreamEventEndEncountered) {
        NSLog(@"即将关闭write stream");
        [self closeWriteStream];
    } else if (type == kCFStreamEventErrorOccurred) {
        NSLog(@"error, error!");
    }
}

void readStreamCallBackFun(CFReadStreamRef stream, CFStreamEventType type, void * userInfo)
{
    StreamViewController *self = (__bridge StreamViewController *)userInfo;
    
    if (type == kCFStreamEventOpenCompleted) {
        NSLog(@"成功打开read server的stream");
    } else if (type == kCFStreamEventEndEncountered) {
        NSLog(@"即将关闭read stream");
        [self closeWriteStream];
    } else if (type == kCFStreamEventErrorOccurred) {
        NSLog(@"读入!");
    } else if (type == kCFStreamEventHasBytesAvailable) {
        NSLog(@"有东西可以读入了啊！！！！");
        [self readDataFromServer];
    }
}

@implementation StreamViewController
- (IBAction)startStreamToServer:(UIButton *)sender
{
    if (!self.writeStreamRef) {
        NSString *host = self.serverHostField.text;
        int port = [self.serverPortField.text intValue];
        [self startStreamToHost:host andPort:port];
    }
}

- (void)startStreamToHost:(NSString *)host
                  andPort:(int)port
{
    // Prepare "self" for C function callback as usual
    CFStreamClientContext ctx = {0, (__bridge void *)self};
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                       (__bridge CFStringRef)host, // hostname or IP address
                                       port,
                                       &_readStreamRef,
                                       &_writeStreamRef);
    
    CFWriteStreamSetProperty(_writeStreamRef, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFReadStreamSetProperty(_readStreamRef, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    CFWriteStreamSetClient(_writeStreamRef,
                           (kCFStreamEventOpenCompleted | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered),
                           writeStreamCallBackFun, // callback C function
                           &ctx);
    
    CFReadStreamSetClient(_readStreamRef,
                          (kCFStreamEventOpenCompleted | kCFStreamEventHasBytesAvailable | kCFStreamEventEndEncountered),
                          readStreamCallBackFun,
                          &ctx);
    
    CFWriteStreamScheduleWithRunLoop(_writeStreamRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFReadStreamScheduleWithRunLoop(_readStreamRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
    // Actually open the stream and connect to server
    if (!CFWriteStreamOpen(_writeStreamRef)) {
        NSLog(@"错误！！！无法打开write流");
        
    }
    
    if (!CFReadStreamOpen(_readStreamRef)) {
        NSLog(@"错误！！！无法打开read流");
    }
}

#pragma mark - 发送数据部分
- (IBAction)sendDataToServer:(UIButton *)sender
{
    if (self.writeStreamRef) {
        NSData *data = [self.dataField.text dataUsingEncoding:NSUTF8StringEncoding];
        // 返回实际写入的字节数，比如一次写太多，没实际写过去的话，收到这么一个表示字节数的，下次再写的时候，自己负责控制移动指针
        // 跳过这么多字节之后，继续完成
        CFIndex bytesWritten = CFWriteStreamWrite(_writeStreamRef, [data bytes], [data length]);
        [self.statusLabel setText:[NSString stringWithFormat:@"status: Wrote %ld bytes...", bytesWritten]];
    } else {
        [self.statusLabel setText:@"还没连接服务器!!!"];
    }
}

// 最后，关闭stream
- (void)closeWriteStream
{
    CFWriteStreamUnscheduleFromRunLoop(_writeStreamRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFWriteStreamClose(self.writeStreamRef);
    CFRelease(self.writeStreamRef);
    self.writeStreamRef = nil;
    [self.statusLabel setText:@"Status: disconnected"];
}

- (void)readDataFromServer
{
    CFIndex numBytesRead = CFReadStreamRead(self.readStreamRef, buffer, 1024);
    NSMutableData* data = [[NSMutableData alloc] init];
    [data appendBytes:buffer length:numBytesRead]; // FIXME!! 到底是buffer还是&buffer，怎么两个试完了都可以啊？？！
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"读入%@", str);
    self.outputTextArea.text = [self.outputTextArea.text stringByAppendingString:[NSString stringWithFormat:@"%@\n", str]];
    [self scrollToBottom];
}

-(void) scrollToBottom {
    [self.outputTextArea scrollRangeToVisible:NSMakeRange([self.outputTextArea.text length], 0)];
    [self.outputTextArea setScrollEnabled:NO];
    [self.outputTextArea setScrollEnabled:YES];
}

// FIXME, 如果从服务器那端关闭的话，只有read stream收到end event，而write stream就没有
// 是不是改正应该是一关就全关比较好啊？
- (void)closeReadStream
{
    CFReadStreamUnscheduleFromRunLoop(_readStreamRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFReadStreamClose(self.readStreamRef);
    CFRelease(self.readStreamRef);
    self.readStreamRef = nil;
    [self.statusLabel setText:@"Status: disconnected"];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem.title = @"CFStream";
    }
    return self;
}


@end
