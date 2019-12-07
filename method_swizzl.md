### Method Swizzlling

#### 一、概述

Objective-C 中的 Method Swizzling 是一项异常强大的技术，它可以允许我们动态地替换方法的实现，实现 Hook 功能，是一种比子类化更加灵活的“重写”方法的方式。

Method Swizzling 是一把双刃剑，使用得当可以让我们非常轻松地实现复杂的功能，而如果一旦误用，它也很可能会给我们的程序带来毁灭性的伤害。但是我们不能因噎废食，当我们理解了Method Swizzling原理之后，它将会变成我们强大的武器。

#### 二、Method Swizzling 的原理

在上篇博文中我们讲过在Objective-C同一个类(及类的继承体系)中，不能存在2个同名的方法，即使参数类型不同也不行。所以下面两个方法在 runtime 看来就是同一个方法：
```
- (void)viewWillAppear:(BOOL)animated;
- (void)viewWillAppear:(NSString *)string;
```
而下面两个方法却是可以共存的：
```
- (void)viewWillAppear:(BOOL)animated;
+ (void)viewWillAppear:(BOOL)animated;
```
因为实例方法和类方法是分别保存在类对象和元类对象中的。


三、Method Swizzling使用

想必大家都用过友盟统计，我们需要在每个页面的 view controller 中添加如下代码：
```
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"PageOne"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"PageOne"];
}
```
这是最简单的方法，直接简单粗暴的在每个控制器中加入统计，复制、粘贴、复制、粘贴…
实际上非常不建议使用这种方法的，不仅消耗时间而且以后非常难以维护。那我们有其他什么好的办法吗

当然我们还可以用以下两种方法：

（1）直接修改每个页面的 view controller 代码，简单粗暴。

（2）子类化 view controller ，并让我们的 view controller 都继承这些子类。

第 1 种方式的缺点是不仅会产生大量重复的代码，而且还很容易遗漏某些页面，非常难维护；第 2 种方式稍微好一点，但是也同样需要我们子类化 UIViewController 、UITableViewController 和 UITabBarController 等不同类型的 view controller 。

除此之外还有什么比较简单优雅的解决方案吗？答案是肯定的，Method Swizzling 就是解决此类问题的最佳方式。

在实现Method Swizzling时，核心代码主要就是一个runtime的C语言API：
```
BJC_EXPORT void method_exchangeImplementations(Method m1, Method m2) 
 __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
 ```
下面我们通过Method Swizzling简单的实现上面那个添加统计的需求。

我们先给UIViewController添加一个Category，然后在Category中的+(void)load方法中添加Method Swizzling方法，我们用来替换的方法也写在这个Category中。由于load类方法是程序运行时这个类被加载到内存中就调用的一个方法，执行比较早，并且不需要我们手动调用。而且这个方法具有唯一性，也就是只会被调用一次，不用担心资源抢夺的问题。

定义Method Swizzling中我们自定义的方法时，需要注意尽量加前缀，以防止和其他地方命名冲突，Method Swizzling的替换方法命名一定要是唯一的，至少在被替换的类中必须是唯一的。

```
#import "UIViewController+swizzling.h"
#import <objc/runtime.h>
@implementation UIViewController (swizzling)

+ (void)load {
    // 通过class_getInstanceMethod()函数从当前对象中的method list获取method结构体，如果是类方法就使用class_getClassMethod()函数获取。
    Method fromMethod = class_getInstanceMethod([self class], @selector(viewDidLoad));
    Method toMethod = class_getInstanceMethod([self class], @selector(swizzlingViewDidLoad));
    /**
     *  我们在这里使用class_addMethod()函数对Method Swizzling做了一层验证，如果self没有实现被交换的方法，会导致失败。
     *  而且self没有交换的方法实现，但是父类有这个方法，这样就会调用父类的方法，结果就不是我们想要的结果了。
     *  所以我们在这里通过class_addMethod()的验证，如果self实现了这个方法，class_addMethod()函数将会返回NO，我们就可以对其进行交换了。
     */
    if (!class_addMethod([self class], @selector(swizzlingViewDidLoad), method_getImplementation(toMethod), method_getTypeEncoding(toMethod))) {
        method_exchangeImplementations(fromMethod, toMethod);
    }
}

// 我们自己实现的方法，也就是和self的viewDidLoad方法进行交换的方法。
- (void)swizzlingViewDidLoad {
    NSString *str = [NSString stringWithFormat:@"%@", self.class];
    // 我们在这里加一个判断，将系统的UIViewController的对象剔除掉
    if(![str containsString:@"UI"]){
        NSLog(@"统计打点 : %@", self.class);
    }
    [self swizzlingViewDidLoad];
}
@end
```

不知道大家注意没有，swizzlingViewDidLoad方法中又调用了[self swizzlingViewDidLoad];，这难道不会产生递归调用吗？

实际上是不会的，Method Swizzling的实现原理可以理解为”方法互换“。假设我们将A和B两个方法进行互换，向A方法发送消息时执行的却是B方法，向B方法发送消息时执行的是A方法。

例如我们上面的代码，系统调用UIViewController的viewDidLoad方法时，实际上执行的是我们实现的swizzlingViewDidLoad方法。而我们在swizzlingViewDidLoad方法内部调用[self swizzlingViewDidLoad];时，执行的是UIViewController的viewDidLoad方法。

四、Method Swizzling类簇

在我们项目开发过程中，经常因为NSArray数组越界或者NSDictionary的key或者value值为nil等问题导致的崩溃，我们可以尝试使用前面知识对NSArray、NSMutableArray、NSDictionary、NSMutableDictionary等类进行Method Swizzling，但是结果发现Method Swizzling根本就不起作用，到底为什么呢？

这是因为Method Swizzling对NSArray这些的类簇是不起作用的。因为这些类簇类，其实是一种抽象工厂的设计模式。抽象工厂内部有很多其它继承自当前类的子类，抽象工厂类会根据不同情况，创建不同的抽象对象来进行使用。例如我们调用NSArray的objectAtIndex:方法，这个类会在方法内部判断，内部创建不同抽象类进行操作。

所以也就是我们对NSArray类进行操作其实只是对父类进行了操作，在NSArray内部会创建其他子类来执行操作，真正执行操作的并不是NSArray自身，所以我们应该对其“真身”进行操作。

下面我们实现了防止NSArray因为调用objectAtIndex:方法，取下标时数组越界导致的崩溃：

```
#import "NSArray+ MyArray.h"
#import "objc/runtime.h"
@implementation NSArray MyArray)
+ (void)load {
    Method fromMethod = class_getInstanceMethod(objc_getClass("__NSArrayI"), @selector(objectAtIndex:));
    Method toMethod = class_getInstanceMethod(objc_getClass("__NSArrayI"), @selector(my_objectAtIndex:));
    method_exchangeImplementations(fromMethod, toMethod);
}

- (id)my_objectAtIndex:(NSUInteger)index {
    if (self.count-1 < index) {
        // 这里做一下异常处理，不然都不知道出错了。
        @try {
            return [self my_objectAtIndex:index];
        }
        @catch (NSException *exception) {
            // 在崩溃后会打印崩溃信息，方便我们调试。
            NSLog(@"---------- %s Crash Because Method %s  ----------\n", class_getName(self.class), __func__);
            NSLog(@"%@", [exception callStackSymbols]);
            return nil;
    }
        @finally {}
    } else {
        return [self my_objectAtIndex:index];
    }
}
@end
```
也就是说__NSArrayI才是NSArray真正的类。我们可以通过runtime函数获取真正的类：
```
objc_getClass("__NSArrayI")
```
下面我们列举一些常用的类簇的“真身”：


五、Method Swizzling使用注意事项

1、Swizzling应该总是在+load中执行

在Objective-C中，运行时会自动调用每个类的两个方法。+load会在类初始加载时调用，+initialize会在第一次调用类的类方法或实例方法之前被调用。这两个方法是可选的，且只有在实现了它们时才会被调用。由于method swizzling会影响到类的全局状态，因此要尽量避免在并发处理中出现竞争的情况。+load能保证在类的初始化过程中被加载，并保证这种改变应用级别的行为的一致性。相比之下，+initialize在其执行时不提供这种保证—事实上，如果在应用中没为给这个类发送消息，则它可能永远不会被调用。

2、Swizzling应该总是在dispatch_once中执行

与上面相同，因为swizzling会改变全局状态，所以我们需要在运行时采取一些预防措施。原子性就是这样一种措施，它确保代码只被执行一次，不管有多少个线程。GCD的dispatch_once可以确保这种行为，我们应该将其作为method swizzling的最佳实践。

3、Method Swizzling有成熟的第三方框架可用

在项目中我们肯定会在很多地方用到Method Swizzling，而且在使用这个特性时有很多需要注意的地方。我们可以将Method Swizzling封装起来，也可以使用一些比较成熟的第三方。
在这里我推荐Github上星最多的一个第三方－jrswizzle

里面核心就两个类，代码看起来非常清爽。

```
#import <Foundation/Foundation.h>
@interface NSObject (JRSwizzle)
+ (BOOL)jr_swizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_;
+ (BOOL)jr_swizzleClassMethod:(SEL)origSel_ withClassMethod:(SEL)altSel_ error:(NSError**)error_;
@end

// MethodSwizzle类
#import <objc/objc.h>
BOOL ClassMethodSwizzle(Class klass, SEL origSel, SEL altSel);
BOOL MethodSwizzle(Class klass, SEL origSel, SEL altSel);

```
