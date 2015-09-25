#import "AppDelegate.h"
#import "PersonsTableViewController.h"
#import "AddPersonViewController.h"
#import "ResolveHostViewController.h"
#import "SocketViewController.h"
#import "StreamViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];

    PersonsTableViewController *ptvc = [[PersonsTableViewController alloc] init];
    AddPersonViewController *apvc = [[AddPersonViewController alloc] init];
    ResolveHostViewController *rhvc = [[ResolveHostViewController alloc] init];
    SocketViewController *svc = [[SocketViewController alloc] init];
    StreamViewController *svc2 = [[StreamViewController alloc] init];
    // 利用UITabBarController控制在两个ViewController之间切换
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[ptvc, apvc, rhvc, svc, svc2];
    self.window.rootViewController = tabBarController;

    [self.window makeKeyAndVisible];
    return YES;
}

@end
