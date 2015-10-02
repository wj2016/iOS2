#import <Foundation/Foundation.h>
#import "Person.h"

@implementation Person

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _name = name;
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"Person [%@] deallocated", self.name);
}

@end