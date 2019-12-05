//
//  TERunTimeLearnTests.m
//  TERunTimeLearnTests
//
//  Created by offcn_Terry on 2019/12/5.
//  Copyright © 2019 offcn_Terry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Student.h"
#import <objc/runtime.h>
@interface TERunTimeLearnTests : XCTestCase

@end

@implementation TERunTimeLearnTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

/**
 *  测试成员变量
 */
- (void)testIvar {
    unsigned int outCount;
    if(class_addIvar([Student class], "_hell", sizeof(id), log2(sizeof(id)), "@")) {
        NSLog(@"Add Ivar Success!");
    }
    else {
        NSLog(@"Add Ivar failed!");
    }
    Ivar *ivarList = class_copyIvarList([Student class], &outCount);
    for (unsigned int i = 0; i < outCount; i++) {
        Ivar ivar = ivarList[i];
        const char *ivarName = ivar_getName(ivar);
        ptrdiff_t offset = ivar_getOffset(ivar);
        const char *types = ivar_getTypeEncoding(ivar);
        NSLog(@"ivar:%s, offset:%zd, type:%s", ivarName, offset, types);
    }
    free(ivarList);
}

/**
 测试属性函数
 */
- (void)testProperty {
    /**
     *  添加property
     */
    objc_property_attribute_t attribute1 = {"T", "@\"NSString\""};
    objc_property_attribute_t attribute2 = {"C", ""};
    objc_property_attribute_t attribute3 = {"N", ""};
    objc_property_attribute_t attribute4 = {"V", "_lcg"};
    objc_property_attribute_t attributesList[] = {attribute1, attribute2, attribute3, attribute4};
    if(class_addProperty([Student class], "lcg", attributesList, 4)) {
        NSLog(@"add property success!");
    }
    else {
        NSLog(@"add property failure!");
    }
    
    /**
     *  打印property的name和property_attribute_t
     */
    unsigned int outCount;
    objc_property_t *propertyList = class_copyPropertyList([Student class], &outCount);
    for (unsigned int i = 0; i < outCount; i++) {
        objc_property_t property = propertyList[i];
        const char *propertyName = property_getName(property);
        const char *attribute = property_getAttributes(property);
        NSLog(@"propertyName: %s, attribute: %s", propertyName, attribute);
        
        unsigned int attributeCount;
        objc_property_attribute_t *attributeList = property_copyAttributeList(property, &attributeCount);
        for (unsigned int j = 0; j < attributeCount; j++) {
            objc_property_attribute_t attribute = attributeList[j];
            const char *name = attribute.name;
            const char *value = attribute.value;
            NSLog(@"attribute name: %s, value: %s", name, value);
        }
    }
}

/**
 测试协议函数
 */
- (void)testProtocolList {
    //添加协议
    Protocol *p = @protocol(StudentDataSource);
    if(class_addProtocol([Student class], p)) {
        NSLog(@"添加协议成功!");
    }
    else {
        NSLog(@"添加协议失败!");
    }
    
    //判断是否实现了指定的协议
    if(class_conformsToProtocol([Student class], p)) {
        NSLog(@"遵循 %s协议", protocol_getName(p));
    }
    else {
        NSLog(@"不遵循 %s协议", protocol_getName(p));
    }
    
    //获取类的协议列表
    unsigned int outCount;
    Protocol * __unsafe_unretained *protocolList = class_copyProtocolList([Student class], &outCount);
    for (unsigned int i = 0; i < outCount; i++) {
        Protocol *protocol = protocolList[i];
        const char *name = protocol_getName(protocol);
        NSLog(@"%s", name);
    }
    free(protocolList);
}
/**
 测试协议版本函数
 */
- (void)testVersion {
    int version = class_getVersion([Student class]);
    NSLog(@"%d", version);
    class_setVersion([Student class], 100);
    version = class_getVersion([Student class]);
    NSLog(@"%d", version);
}

/**
 创建新的类
 */
-(void)testAddClassTest{
    Class MyClass = objc_allocateClassPair([NSObject class], "myclass", 0);
    //添加一个NSString的变量，第四个参数是对其方式，第五个参数是参数类型
    if (class_addIvar(MyClass, "myIvar", sizeof(NSString *), 0, "@")) {
        NSLog(@"add ivar success");
    }
    //myclasstest是已经实现的函数，"v@:"这种写法见参数类型连接
    class_addMethod(MyClass, @selector(method0:), (IMP)mothod1, "v@:");
    //注册这个类到runtime系统中就可以使用他了
    objc_registerClassPair(MyClass);
    //生成了一个实例化对象
    id myobj = [[MyClass alloc] init];
    NSString *str = @"lifengfeng";
    //给刚刚添加的变量赋值
    //object_setInstanceVariable(myobj, "myIvar", (void *)&str);在ARC下不允许使用
    [myobj setValue:str forKey:@"myIvar"];
    //调用myclasstest方法，也就是给myobj这个接受者发送myclasstest这个消息
    [myobj method0:10];
    
}

//这个方法实际上没有被调用,但是必须实现否则不会调用下面的方法
- (void)method0:(int)a
{
    
}
//调用的是这个方法
void mothod1(id self, SEL _cmd, int a) //self和_cmd是必须的，在之后可以随意添加其他参数
{
    
    Ivar v = class_getInstanceVariable([self class], "myIvar");
    //返回名为itest的ivar的变量的值
    id o = object_getIvar(self, v);
    //成功打印出结果
    NSLog(@"%@", o);
    NSLog(@"int a is %d", a);
}

- (void)testClassCreateInstance {
    id theObject = class_createInstance(NSString.class, sizeof(unsigned));
    id str1 = [theObject init];
    NSLog(@"%@", [str1 class]);
    id str2 = [[NSString alloc] initWithString:@"test"];
    NSLog(@"%@", [str2 class]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
