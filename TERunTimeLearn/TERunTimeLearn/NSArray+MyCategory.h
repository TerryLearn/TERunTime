//
//  NSArray+MyCategory.h
//  TERunTimeLearn
//
//  Created by offcn_Terry on 2019/12/5.
//  Copyright © 2019 offcn_Terry. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (MyCategory)

//不会生成添加属性的getter和setter方法，必须我们手动生成
@property (nonatomic, copy) NSString *blog;

@end

NS_ASSUME_NONNULL_END
