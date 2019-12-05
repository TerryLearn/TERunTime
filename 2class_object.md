### 类与对象的操作

#### 一、类与对象的操作函数

runtime提供了大量的函数来操作类与对象，操作类的函数一般前缀是class，而操作对象的函数一般前缀是objc。

##### 1、类相关操作函数

```
// 获取类的类名
const char * class_getName ( Class cls );
// 获取类的父类
Class class_getSuperclass ( Class cls );
 
// 判断给定的Class是否是一个元类
BOOL class_isMetaClass ( Class cls );
// 获取实例大小
size_t class_getInstanceSize ( Class cls );
```
##### 2、成员变量相关操作函数

```
// 获取类中指定名称实例成员变量的信息
Ivar class_getInstanceVariable ( Class cls, const char *name );
 
// 获取类成员变量的信息
Ivar class_getClassVariable ( Class cls, const char *name );
 
// 添加成员变量
BOOL class_addIvar ( Class cls, const char *name, size_t size, uint8_t alignment, const char *types );
 
// 获取整个成员变量列表
Ivar * class_copyIvarList ( Class cls, unsigned int *outCount );
```
需要注意：

（1）class_copyIvarList：获取的是所有成员实例属性，与property获取不一样。

（2）class_addIvar: OC不支持往已存在的类中添加实例变量，因此不管是系统库提供的类，还是我们自定义的类，都无法动态给它添加成员变量。但，如果是我们通过运行时来创建的类，我们可以使用class_addIvar来添加。不过，需要注意的是，这个方法只能在objc_allocateClassPair函数与objc_registerClassPair之间调用。另外，这个类也不能是元类。

```
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
```

##### 3、属性操作函数

```
// 获取指定的属性
objc_property_t class_getProperty ( Class cls, const char *name );
 
// 获取属性列表
objc_property_t * class_copyPropertyList ( Class cls, unsigned int *outCount );
 
// 为类添加属性
BOOL class_addProperty ( Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount );
 
// 替换类的属性
void class_replaceProperty ( Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount );
```
这一种方法也是针对ivar来操作的，不过它只操作那些property的值，包括扩展中的property。

例如：

```
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

```
上面代码有几个知识点需要说一下：

(1) 其中property_attribute的相关内容需要说明下。

property_attribute为T@”NSString”、&、N、V_exprice时：

T 是固定的，放在第一个
@”NSString” 代表这个property是一个字符串对象
& 代表强引用，其中与之并列的是：’C’代表Copy，’&’代表强引用，’W’表示weak，assign为空，默认为assign。
N 区分的nonatomic和atomic，默认为atomic，atomic为空，’N’代表是nonatomic
V_exprice V代表变量，后面紧跟着的是成员变量名，代表这个property的成员变量名为_exprice
property_attribute为T@”NSNumber”、R、N、V_yearsOld时：

T 是固定的，放在第一个
@”NSNumber” 代表这个property是一个NSNumber对象
R 代表readOnly属性，readwrite时为空
N 区分的nonatomic和atomic，默认为atomic，atomic为空，’N’代表是nonatomic
V_yearsOld V代表变量，后面紧跟着的是成员变量名，代表这个property的成员变量名为_yearsOld。
（2）添加property，property_attribute_t是一个结构体，没有具体创建的方法，我们就只能使用{}这样结构体直接赋值过去。而且，添加property成功之后，它并不会生成实例属性、setter方法和getter方法。如果要真正调用的话，还需要我们自己添加对应的setter和getter方法。

##### 4、协议相关函数

```
// 添加协议
BOOL class_addProtocol ( Class cls, Protocol *protocol );
 
// 返回类是否实现指定的协议
BOOL class_conformsToProtocol ( Class cls, Protocol *protocol );
 
// 返回类实现的协议列表
Protocol * class_copyProtocolList ( Class cls, unsigned int *outCount );
```

```
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
```
所以，可以使用runtime添加协议。

##### 6、版本号（Version)

版本的使用两个方法，获取版本和设置版本，如下：

```
- (void)testVersion {
    int version = class_getVersion([Student class]);
    NSLog(@"%d", version);
    class_setVersion([Student class], 100);
    version = class_getVersion([Student class]);
    NSLog(@"%d", version);
}
```

#### 二、动态创建类和对象

##### 1、动态创建类

涉及以下函数：

```
// 创建一个新类和元类
Class objc_allocateClassPair ( Class superclass, const char *name, size_t extraBytes );
 
// 销毁一个类及其相关联的类
void objc_disposeClassPair ( Class cls );
 
// 在应用中注册由objc_allocateClassPair创建的类
void objc_registerClassPair ( Class cls );
```

其中：

（1）objc_allocateClassPair函数：如果我们要创建一个根类，则superclass指定为Nil。extraBytes通常指定为0，该参数是分配给类和元类对象尾部的索引ivars的字节数。

（2）为了创建一个新类，我们需要调用objc_allocateClassPair。然后使用诸如class_addMethod，class_addIvar等函数来为新创建的类添加方法、实例变量和属性等。完成这些后，我们需要调用objc_registerClassPair函数来注册类，之后这个新类就可以在程序中使用了。

（3）实例方法和实例变量应该添加到类自身上，而类方法应该添加到类的元类上。

（4）objc_disposeClassPair只能销毁由objc_allocateClassPair创建的类，当有实例存在或者它的子类存在时，调用这个函数会抛出异常。

```
-(void)addClassTest{
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
    [myobj method0:10];}

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
```
上面为类添加了成员变量（ivar），也可以结合属性操作方法为类添加属性（property）。

属性和成员变量区别：成员变量主要是适用于iOS5之前的开发，需要程序员手动进行内存管理。iOS5之后（包括iOS5）引入了ARC（Automatic Reference Counting）同过在property中使用strong,weak等标记自动对内存进行管理。也就是说进行iOS5及以后系统版本的开发，可以放心的使用property，而无需对其进行手动的内存管理。


##### 2、动态创建对象

动态创建对象的函数如下：

```
// 创建类实例
id class_createInstance ( Class cls, size_t extraBytes );
// 在指定位置创建类实例
id objc_constructInstance ( Class cls, void *bytes );
// 销毁类实例
void * objc_destructInstance ( id obj );
```
class_createInstance函数：创建实例时，会在默认的内存区域为类分配内存。extraBytes参数表示分配的额外字节数。这些额外的字节可用于存储在类定义中所定义的实例变量之外的实例变量。该函数在ARC环境下无法使用。

调用class_createInstance的效果与+alloc方法类似。不过在使用class_createInstance时，我们需要确切的知道我们要用它来做什么。在下面的例子中，我们用NSString来测试一下该函数的实际效果

```
id theObject = class_createInstance(NSString.class, sizeof(unsigned));
id str1 = [theObject init];
NSLog(@"%@", [str1 class]);
id str2 = [[NSString alloc] initWithString:@"test"];
NSLog(@"%@", [str2 class]);
```
可以看到，使用class_createInstance函数获取的是NSString实例，而不是类簇中的默认占位符类__NSCFConstantString。

objc_constructInstance方法：在指定的位置(bytes)创建类实例。

objc_destructInstance方法：销毁一个类的实例，但不会释放并移除任何与其相关的引用。

三、其他类和对象相关操作函数

```
// 获取已注册的类定义的列表
int objc_getClassList ( Class *buffer, int bufferCount );
 
// 创建并返回一个指向所有已注册类的指针列表
Class * objc_copyClassList ( unsigned int *outCount );
 
// 返回指定类的类定义
Class objc_lookUpClass ( const char *name );
Class objc_getClass ( const char *name );
Class objc_getRequiredClass ( const char *name );
 
// 返回指定类的元类
Class objc_getMetaClass ( const char *name );


// 返回指定对象的一份拷贝
id object_copy ( id obj, size_t size );
 
// 释放指定对象占用的内存
id object_dispose ( id obj );
// 修改类实例的实例变量的值
Ivar object_setInstanceVariable ( id obj, const char *name, void *value );
 
// 获取对象实例变量的值
Ivar object_getInstanceVariable ( id obj, const char *name, void **outValue );
 
// 返回指向给定对象分配的任何额外字节的指针
void * object_getIndexedIvars ( id obj );
 
// 返回对象中实例变量的值
id object_getIvar ( id obj, Ivar ivar );
 
// 设置对象中实例变量的值
void object_setIvar ( id obj, Ivar ivar, id value );
// 返回给定对象的类名
const char * object_getClassName ( id obj );
 
// 返回对象的类
Class object_getClass ( id obj );
 
// 设置对象的类
Class object_setClass ( id obj, Class cls );

```
[转载地址](https://imlifengfeng.github.io/article/392/)
