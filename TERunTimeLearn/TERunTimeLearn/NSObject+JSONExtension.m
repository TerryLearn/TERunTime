//
//  NSObject+JSONExtension.m
//  TEObjc_Runtime
//
//  Created by offcn_Terry on 2019/11/27.
//  Copyright © 2019 offcn_Terry. All rights reserved.
//

#import "NSObject+JSONExtension.h"
#import <objc/runtime.h>

@implementation NSObject (JSONExtension)

- (instancetype)initWithDictionary:(NSDictionary *)dic {
    if (self = [self init]) {
        unsigned int count;
        objc_property_t *propertyList = class_copyPropertyList([self class], &count);
        for (unsigned int i=0; i<count; i++) {
            const char *propertyName = property_getName(propertyList[i]);
            NSString *name = [NSString stringWithUTF8String:propertyName];
            id value = [dic objectForKey:name];
            if (value) {
                [self setValue:value forKey:name];
            }
        }
        free(propertyList);
    }
    return self;
}


// 这里测试利用 Runtime 来实现自动归解档
- (void)initAllPropertiesWithCoder:(NSCoder *)coder {
    
    unsigned int count;
    objc_property_t *propertyList = class_copyPropertyList([self class], &count);
    for (unsigned int i=0; i<count; i++) {
        const char *propertyName = property_getName(propertyList[i]);
        NSString *name = [NSString stringWithUTF8String:propertyName];
        
        id value = [coder decodeObjectForKey:name];
        [self setValue:value forKey:name];
    }
    free(propertyList);
}

- (void)encodeAllPropertiesWithCoder:(NSCoder *)coder {
    
    unsigned int count;
    objc_property_t *propertyList = class_copyPropertyList([self class], &count);
    for (unsigned int i=0; i<count; i++) {
        const char *propertyName = property_getName(propertyList[i]);
        NSString *name = [NSString stringWithUTF8String:propertyName];
        
        id value = [self valueForKey:name];
        [coder encodeObject:value forKey:name];
    }
    free(propertyList);
}


@end
