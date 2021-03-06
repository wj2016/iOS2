#import "DemoBundleViewController.h"

@interface DemoBundleViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *logoView;

@end

@implementation DemoBundleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem.title = @"bundle内文件";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadLogoView];
}

/*
 * 这里利用URLForResource获取bundle内的资源文件
 */
- (void)loadLogoView
{
    NSURL *logoImageFileUrl = [[NSBundle mainBundle] URLForResource:@"gradle_icon" withExtension:@"png"];
    NSString *path = [logoImageFileUrl path];
    NSLog(@"logo file path: %@", path);
    NSData *logoData = [NSData dataWithContentsOfURL:logoImageFileUrl];
    UIImage *logoImage = [UIImage imageWithData:logoData];
    self.logoView.image = logoImage;
}

@end
