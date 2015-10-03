#import <Foundation/Foundation.h>
#import "Person.h"

#pragma mark - ARC内存管理演示
// 先来演示最基本的ARC原理
void demoMemory1()
{
    __unused Person *p1 = [[Person alloc] initWithName:@"111"];
    {
        __unused Person *p2 = [[Person alloc] initWithName:@"222"];
    } // 在scope结束时候p2就先dealloc了，在非ARC的时候，这里要显式的加入release
    NSLog(@"回收p2");
    
    Person *p3 = [[Person alloc] initWithName:@"3333"];
    p3 = nil;
    NSLog(@"回收p3");
}  // 函数返回的时候，p1才被dealloc

// 演示一下weak解决循环依赖的问题
void demoMemory2()
{
    {
        Person *p1 = [[Person alloc] initWithName:@"111"];
        Person *p2 = [[Person alloc] initWithName:@"222"];
        p1.partner = p2;
        p2.partner = p1;
        NSLog(@"p1->p2: %@", p1.partner);
        p2 = nil;
        NSLog(@"p1->p2: %@", p1.partner); // weak的另一边自动设置为nil了！
        NSLog(@"因为weak的关系，p2就可以消失了");
    } // 通过weak属性避免循环依赖的问题，假设属性是strong的话，p1，p2就都不会在这里被回收了
    {
        Person *p3 = [[Person alloc] initWithName:@"333"];
        __unused __weak Person *p4 = p3;
        __unused __unsafe_unretained Person *p5 = p3;
        p3 = nil;
        NSLog(@"因为[333]只剩weak指向了，所以也回收了");
        // 此时p4已经为nil了，但是p5就不会，还是指向原来地址
        NSLog(@"weak的对象没有了之后，会自动设为nil，比如现在p4: %@", p4);
        // NSLog(@"但是__unsafe_unretaind对象就不会, p5: %@", p5);
    }
}

#pragma mark - Blocks演示
void demoBlock1()
{
    int x = 100;
    __block int y = 100;
    int (^myPlus)(int) = ^int(int num) {
        NSLog(@"y的话，现在是: %d", y); // y是__block声明，是个reference，所以外部的y改变，这里就会拿到新的值
        y = 888; // 可以改变y，因为用了__block声明
        return x + num;
    };
    // LLDB调试的话call ((int(^)(int))myPlus)(88)

    int a1 = myPlus(3);
    NSLog(@"a1 == %d", a1);

    // 改变x跟y的值
    x = 888;
    y = 999;
    int a2 = myPlus(3); // a2的结果不变，因为x的值已经绑定走了closure了
    NSLog(@"a2 == %d", a2);
    NSLog(@"y == %d", y);
}

void demoBlock2()
{
    // 不改变外部变量值，类似C语言指针常量的效果
    // 虽然指针本身是const了，但是可以改变其指向东西的内容
    NSMutableArray *array = [[NSMutableArray alloc] init];
    void (^blk)(void) = ^{
        id obj = [[NSObject alloc] init];
        // array = [[NSArray alloc] init]; // ERROR 相当于改变指针本身，就是禁止的
        [array addObject:obj];             // OK    相当于改变指针所指内容，就可以
    };
    NSLog(@"array数量: %lu", [array count]); // 刚开始是0
    blk();                                  // block执行时候添加了一个
    NSLog(@"array数量: %lu", [array count]); // 就变为1了
}

#pragma mark - main函数跑起来所有的
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"==进入demoMemory1");
        demoMemory1();
        NSLog(@"==完成demoMemory1");
        
        NSLog(@"==进入demoMemory2");
        demoMemory2();
        NSLog(@"==完成demoMemory2");
        
        NSLog(@"==进入demo block");
        demoBlock1();
        demoBlock2();
        NSLog(@"==完成demo block");
    }
    return 0;
}
