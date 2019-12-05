### 成员变量和属性

#### 一.成员变量和属性的本质是什么 
下面主要介绍这点。

#### 二、类型编码

作为对Runtime的补充，编译器将每个方法的返回值和参数类型编码为一个字符串，并将其与方法的selector关联在一起。因此我们可以使用@encode编译器指令来获取它。当给定一个类型时，@encode返回这个类型的字符串编码。这些类型可以是诸如int、指针这样的基本类型，也可以是结构体、类等类型。事实上，任何可以作为sizeof()操作参数的类型都可以用于@encode()。

注意：Objective-C不支持long double类型。@encode(long double)返回d，与double是一样的。

一个数组的类型编码位于方括号中；其中包含数组元素的个数及元素类型。如以下示例：
```
float a[] = {1.0, 2.0, 3.0};
NSLog(@"array encoding type: %s", @encode(typeof(a)));
2016-12-24 22:53:54.731 RuntimeTest[942:50791] array encoding type: [3f]
```
另外，还有些编码类型，@encode虽然不会直接返回它们，但它们可以作为协议中声明的方法的类型限定符。

对于属性而言，还会有一些特殊的类型编码，以表明属性是只读、拷贝、retain等等。

#### 三、成员变量

1、定义
Ivar: 实例变量类型，是一个指向objc_ivar结构体的指针

```
typedef struct objc_ivar *Ivar;
struct objc_ivar {
    char *ivar_name                 OBJC2_UNAVAILABLE;  // 变量名
    char *ivar_type                 OBJC2_UNAVAILABLE;  // 变量类型
    int ivar_offset                 OBJC2_UNAVAILABLE;  // 基地址偏移字节
#ifdef __LP64__
    int space                       OBJC2_UNAVAILABLE;
#endif
}
```
2、操作函数

```
// 获取整个成员变量列表
Ivar * class_copyIvarList ( Class cls, unsigned int *outCount );

// 获取成员变量名
const char * ivar_getName ( Ivar v );

// 获取成员变量类型编码
const char * ivar_getTypeEncoding ( Ivar v );

// 获取类中指定名称实例成员变量的信息
Ivar class_getInstanceVariable ( Class cls, const char *name );

// 获取成员变量的偏移量
ptrdiff_t ivar_getOffset ( Ivar v );
```

3、使用实例

Model的头文件声明如下：
```
@interface Model : NSObject {
        NSString * _str1;
    }

@property NSString * str2;
@property (nonatomic, copy) NSDictionary * dict1;

@end
```
获取其成员变量：
```
unsigned int outCount = 0;
Ivar * ivars = class_copyIvarList([Model class], &outCount);
for (unsigned int i = 0; i < outCount; i ++) {
      Ivar ivar = ivars[i];
      const char * name = ivar_getName(ivar);
      const char * type = ivar_getTypeEncoding(ivar);
      NSLog(@"类型为 %s 的 %s ",type, name);
}
free(ivars);

```

```
runtimeIvar[602:16885] 类型为 @"NSString" 的 _str1 
runtimeIvar[602:16885] 类型为 @"NSString" 的 _str2 
runtimeIvar[602:16885] 类型为 @"NSDictionary" 的 _dict1
```

三、属性

1、定义
objc_property_t：声明的属性的类型，是一个指向objc_property结构体的指针

```
typedef struct objc_property *Property;
typedef struct objc_property *objc_property_t;//这个更常用
```

2 操作函数

```
// 获取指定的属性
objc_property_t class_getProperty ( Class cls, const char *name );
 
// 获取属性列表，注意：使用class_copyPropertyList并不会获取无@property声明的成员变量
objc_property_t * class_copyPropertyList ( Class cls, unsigned int *outCount );
 
// 为类添加属性
BOOL class_addProperty ( Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount );
 
// 替换类的属性
void class_replaceProperty ( Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount );

// 获取属性名  
const charchar * property_getName ( objc_property_t property );  
  
// 获取属性特性描述字符串  
const charchar * property_getAttributes ( objc_property_t property );  
  
// 获取属性中指定的特性  
charchar * property_copyAttributeValue ( objc_property_t property, const charchar *attributeName );  
  
// 获取属性的特性列表  
objc_property_attribute_t * property_copyAttributeList ( objc_property_t property, unsigned intint *outCount );
```
说明：

（1）class_copyPropertyList、property_copyAttributeList 函数，返回的数组在使用完后一定要调用free()释放，防止内存泄露。

（2）property_getAttributes函数返回objc_property_attribute_t结构体列表，objc_property_attribute_t结构体包含name和value，常用的属性如下：

```
属性类型  name值：T  value：变化
编码类型  name值：C(copy) &(strong) W(weak) 空(assign) 等 value：无
非/原子性 name值：空(atomic) N(Nonatomic)  value：无
变量名称  name值：V  value：变化
```

#### 四、应用实例

1、Json到Model的转化

在开发中相信最常用的就是接口数据需要转化成Model了，也就是所谓的字典转模型（json->字典->模型）。很多开发者也都使用著名的第三方库如JsonModel、Mantle或MJExtension等，如果只用而不知其所以然，那真和“搬砖”没啥区别了，下面我们使用runtime去解析json来给Model赋值。

原理：用runtime提供的函数遍历Model自身所有属性，如果属性在json中有对应的值，则将其赋值。

具体实现如下：

```
- (instancetype)initWithDict:(NSDictionary *)dict {

    if (self = [self init]) {
        //(1)获取类的属性及属性对应的类型
        NSMutableArray * keys = [NSMutableArray array];
        NSMutableArray * attributes = [NSMutableArray array];
        /*
         * 例子
         * name = value3 attribute = T@"NSString",C,N,V_value3
         * name = value4 attribute = T^i,N,V_value4
         */
        unsigned int outCount;
        objc_property_t * properties = class_copyPropertyList([self class], &outCount);
        for (int i = 0; i < outCount; i ++) {
            objc_property_t property = properties[i];
            //通过property_getName函数获得属性的名字
            NSString * propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            [keys addObject:propertyName];
            //通过property_getAttributes函数可以获得属性的名字和@encode编码
            NSString * propertyAttribute = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
            [attributes addObject:propertyAttribute];
        }
        //立即释放properties指向的内存
        free(properties);

        //(2)根据类型给属性赋值
        for (NSString * key in keys) {
            if ([dict valueForKey:key] == nil) continue;
            [self setValue:[dict valueForKey:key] forKey:key];
        }
    }
    return self;

}

```
大家可以进一步思考：
（1）如何识别基本数据类型的属性并处理
（2）空（nil，null）值的处理
（3）json中嵌套json（Dict或Array）的处理
尝试解决以上问题，你也能写出属于自己的功能完备的Json转Model库。

2、快速归档

有时候我们要对一些信息进行归档，如用户信息类UserInfo，这将需要重写initWithCoder和encodeWithCoder方法，并对每个属性进行encode和decode操作。那么问题来了：当属性只有几个的时候可以轻松写完，如果有几十个属性呢？那不得写到天荒地老？

原理：用runtime提供的函数遍历Model自身所有属性，并对属性进行encode和decode操作。
具体实现如下：

```
- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        unsigned int outCount;
        Ivar * ivars = class_copyIvarList([self class], &outCount);
        for (int i = 0; i < outCount; i ++) {
            Ivar ivar = ivars[i];
            NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)];
            [self setValue:[aDecoder decodeObjectForKey:key] forKey:key];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList([self class], &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)];
        [aCoder encodeObject:[self valueForKey:key] forKey:key];
    }
}
```

3、访问私有变量

我们知道，OC中没有真正意义上的私有变量和方法，要让成员变量私有，要放在m文件中声明，不对外暴露。如果我们知道这个成员变量的名称，可以通过runtime获取成员变量，再通过getIvar来获取它的值。
方法：


```
Ivar ivar = class_getInstanceVariable([Model class], "_str1");
NSString * str1 = object_getIvar(model, ivar);
```
