//
//  TERunTimeVarAndProperty.m
//  TERunTimeLearnTests
//
//  Created by offcn_Terry on 2019/12/5.
//  Copyright © 2019 offcn_Terry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Student.h"
#import "ObjectA.h"
#import <objc/runtime.h>
#import "NSObject+JSONExtension.h"
#import "NSArray+Mycategory.h"

@interface TERunTimeVarAndProperty : XCTestCase

@end

@implementation TERunTimeVarAndProperty

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testEncode {
    float a[] = {1.0, 2.0, 3.0};
    NSLog(@"array encoding type: %s", @encode(typeof(a)));
}
/**
 获取成员变量
 */
- (void)testGetVar{
    unsigned int outCount = 0;
    Ivar * ivars = class_copyIvarList([Student class], &outCount);
    for (unsigned int i = 0; i < outCount; i ++) {
          Ivar ivar = ivars[i];
          const char * name = ivar_getName(ivar);
          const char * type = ivar_getTypeEncoding(ivar);
          NSLog(@"类型为 %s 的 %s ",type, name);
    }
    free(ivars);
}

/**
 属性获取测试
 */
-(void)testProperty{
    unsigned int outCount = 0;
    objc_property_t * properties = class_copyPropertyList([Student class], &outCount);
    for (unsigned int i = 0; i < outCount; i ++) {
        objc_property_t property = properties[i];
        //属性名
        const char * name = property_getName(property);
        //属性描述
        const char * propertyAttr = property_getAttributes(property);
        NSLog(@"属性描述为 %s 的 %s ", propertyAttr, name);

        //属性的特性
        unsigned int attrCount = 0;
        objc_property_attribute_t * attrs = property_copyAttributeList(property, &attrCount);
        for (unsigned int j = 0; j < attrCount; j ++) {
            objc_property_attribute_t attr = attrs[j];
            const char * name = attr.name;
            const char * value = attr.value;
            NSLog(@"属性的描述：%s 值：%s", name, value);
        }
        free(attrs);
        NSLog(@"\n");
    }
    free(properties);
}

/**
 json转model
 */
- (void)testValueKey{
    NSDictionary *info = @{@"title":@"标题",@"count":@1,@"test":@"hello"};
    ObjectA *objectA = [[ObjectA alloc] initWithDictionary:info];
    NSLog(@"key%@ value", objectA.title);
}

/**
 归档
 */
- (void)testArchtive{
    NSDictionary *info = @{@"title": @"标题11", @"count": @(11)};
    ObjectA*objectA = [[ObjectA alloc] initWithDictionary:info];
    NSString *path = [NSString stringWithFormat:@"%@/objectA.plist", NSHomeDirectory()];
    [NSKeyedArchiver archiveRootObject:objectA toFile:path];
    // 解档
    ObjectA *objectB = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    NSLog(@"%@", objectB.title);
    NSLog(@"%ld", (long)objectB.count);
    // 输出：11
}

/**私有变量*/
- (void)testPrivateVar {
    Ivar ivar = class_getInstanceVariable([Student class], "_str1");
    Student *student = [Student new];
    NSString * str1 = object_getIvar(student, ivar);
    NSLog(@"str:%@",str1);
}

/**
 关联对象测试
 */
-(void)testcategoryTest{
    NSArray *myArray = [[NSArray alloc]init];
    myArray.blog = @"http://www.imlifengfeng.com";
    NSLog(@"谁说Category不能添加属性？我用Category为NSArray添加了一个blog属性，blog=%@",myArray.blog);
    
}


@end
