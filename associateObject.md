### 关联对象

#### 一、概述

如何给NSArray添加一个属性（不能使用继承）？不能用继承，难道用分类？但是分类只能添加方法不能添加属性啊（Category不允许为已有的类添加新的成员变量，实际上允许添加属性的，同样可以使用@property，但是不会生成_变量（带下划线的成员变量），也不会生成添加属性的getter和setter方法，所以，尽管添加了属性，也无法使用点语法调用getter和setter方法。但实际上可以使用runtime去实现Category为已有的类添加新的属性并生成getter和setter方法）

关联对象是指某个OC对象通过一个唯一的key连接到一个类的实例上。
举个例子：xiaoming是Person类的一个实例，他的dog（一个OC对象）通过一根绳子（key）被他牵着散步，这可以说xiaoming和dog是关联起来的，当然xiaoming可以牵着多个dog

#### 二、如何关联对象

runtime提供给我们的方法：

```
//关联对象
void objc_setAssociatedObject(id object, const void *key, id value, objc_AssociationPolicy policy)

//获取关联的对象
id objc_getAssociatedObject(id object, const void *key)

//移除关联的对象
void objc_removeAssociatedObjects(id object)
```
参数说明：
```
id object：被关联的对象（如xiaoming）
const void *key：关联的key，要求唯一
id value：关联的对象（如dog）
objc_AssociationPolicy policy：内存管理的策略
```

objc_AssociationPolicy policy的enum值有：

```
typedef OBJC_ENUM(uintptr_t, objc_AssociationPolicy) {

    OBJC_ASSOCIATION_ASSIGN = 0,           /**< Specifies a weak reference to the associated object. */
    
    OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1, /**< Specifies a strong reference to the associated object. 
                                            *   The association is not made atomically. */
    
    OBJC_ASSOCIATION_COPY_NONATOMIC = 3,   /**< Specifies that the associated object is copied. 
                                            *   The association is not made atomically. */
    
    OBJC_ASSOCIATION_RETAIN = 01401,       /**< Specifies a strong reference to the associated object.
                                            *   The association is made atomically. */
    
    OBJC_ASSOCIATION_COPY = 01403          /**< Specifies that the associated object is copied.
                                            *   The association is made atomically. */

}
```

当对象被释放时，会根据这个策略来决定是否释放关联的对象，当策略是RETAIN/COPY时，会释放（release）关联的对象，当是ASSIGN，将不会释放。
值得注意的是，我们不需要主动调用removeAssociated来接触关联的对象，如果需要解除指定的对象，可以使用setAssociatedObject置nil来实现


#### 三、应用实例（Category添加属性并生成getter和setter方法）

我们现在来解决峰哥在概述中提出的问题：如何给NSArray添加一个属性（不能使用继承）？

我们现在为NSArray增加一个blog属性：

我们先按照往常方式创建一个NSArray的Category，NSArray+MyCategory.h文件：

```
#import <Foundation/Foundation.h>

@interface NSArray (MyCategory)

//不会生成添加属性的getter和setter方法，必须我们手动生成
@property (nonatomic, copy) NSString *blog;

@end
```

```
#import "NSArray+MyCategory.h"
#import <objc/runtime.h>

@implementation NSArray (MyCategory)

// 定义关联的key
static const char *key = "blog";


/**
 blog的getter方法
 */
- (NSString *)blog
{
    // 根据关联的key，获取关联的值。
    return objc_getAssociatedObject(self, key);
}

/**
 blog的setter方法
 */
- (void)setBlog:(NSString *)blog
{
    // 第一个参数：给哪个对象添加关联
    // 第二个参数：关联的key，通过这个key获取
    // 第三个参数：关联的value
    // 第四个参数:关联的策略
    objc_setAssociatedObject(self, key, blog, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
```

测试代码和打印结果
```
-(void)categoryTest{
    NSArray *myArray = [[NSArray alloc]init];
    myArray.blog = @"http://www.imlifengfeng.com";
    NSLog(@"谁说Category不能添加属性？我用Category为NSArray添加了一个blog属性，blog=%@",myArray.blog);
    
}
2016-12-25 20:00:37.824 RunTimeTest[9447:958867] 谁说Category不能添加属性？我用Category为NSArray添加了一个blog属性


```
