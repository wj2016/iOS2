#import <Foundation/Foundation.h>

@interface Person : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, weak) Person *partner;

- (instancetype)initWithName:(NSString *)name;

@end
