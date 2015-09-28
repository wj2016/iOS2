#import "DemoFileViewController.h"

@interface DemoFileViewController ()

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UITextView *fileContentView;
@property (weak, nonatomic) IBOutlet UITextField *filenameField;

@end

@implementation DemoFileViewController

#pragma mark - 沙盒目录操作
- (void)demoPaths
{
    NSArray *paths;
    paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES); // Library/Application Support
    NSLog(@"applicatoin support dir: %@", paths);
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); // Documents
    NSLog(@"docuement dir: %@", paths);
    paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES); // Library/Caches
    NSLog(@"applicatoin dir: %@", paths);
}

/*
 * 获取应用沙盒所在Documents目录的路径
 */
- (NSString *)documentsDirPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirPath = paths[0];
    return documentsDirPath;
}

#pragma mark - 沙盒文件操作
- (IBAction)openFile:(UIButton *)sender
{
    NSString *filename = self.filenameField.text;
    if (![filename isEqual: @""]) { // 有文件名
        NSString *filePath = [[self documentsDirPath] stringByAppendingPathComponent:filename];
        // 判断文件是否已经存在
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        if (fileExists) {
            // 文件存在，用NSString读取文件, read file
            NSString *content = [NSString stringWithContentsOfFile:filePath
                                                          encoding:NSUTF8StringEncoding
                                                             error:nil];
            self.fileContentView.text = content;
            self.infoLabel.text = [NSString stringWithFormat:@"文件 %@ 已经存在，打开", filename];;
        } else {
            // 文件不存在，创建, create file
            [[NSFileManager defaultManager] createFileAtPath:filePath
                                                    contents:nil
                                                  attributes:nil];
            self.fileContentView.text = @"";
            self.infoLabel.text = [NSString stringWithFormat:@"建立新文件 %@ ", filename];;
        }
    } else {
        // 文件名部分为空
        self.infoLabel.text = @"文件名为空";
    }
}

- (IBAction)saveFile:(UIButton *)sender
{
    NSString *filename = self.filenameField.text;
    NSLog(@"文件名：<%@>", filename);
    if (![filename isEqual: @""]) {
        NSString *filePath = [[self documentsDirPath] stringByAppendingPathComponent:filename];
        NSString *fileString = self.fileContentView.text;
        // 利用NSString，写入文件
        [fileString writeToFile:filePath
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:nil];
        self.infoLabel.text = [NSString stringWithFormat:@"保存文件 %@ ", filename];;
    } else {
        // 文件名部分为空
        self.infoLabel.text = @"文件名为空";
    }
}

- (IBAction)showFileList:(UIButton *)sender
{
    NSString *documentsPath = [self documentsDirPath];
    // 利用NSFileManager列出所有Documents目录下的文件
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsPath error:nil];
    NSString *filesString = [NSString stringWithFormat:@"文件名：%@", files];
    self.fileContentView.text = filesString;
}

#pragma mark - 常规操作
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem.title = @"普通目录文件";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self demoPaths];
    
    // 点击背景处关闭键盘
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

@end
