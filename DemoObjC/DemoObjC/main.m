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
        __unsafe_unretained Person *p5 = p3;
        p3 = nil;
        NSLog(@"因为[333]只剩weak指向了，所以也回收了");
        // 此时p4已经为nil了，但是p5就不会，还是指向原来地址
        NSLog(@"weak的对象没有了之后，会自动设为nil，比如现在p4: %@", p4);
        NSLog(@"但是__unsafe_unretaind对象就不会, p5: %@", p5);
    }
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
    }
    return 0;
}
