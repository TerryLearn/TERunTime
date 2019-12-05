//
//  NSObject+JSONExtension.h
//  TEObjc_Runtime
//
//  Created by offcn_Terry on 2019/11/27.
//  Copyright © 2019 offcn_Terry. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (JSONExtension)
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
// 解档所有属性
- (void)initAllPropertiesWithCoder:(NSCoder *)coder;

// 归档所有属性
- (void)encodeAllPropertiesWithCoder:(NSCoder *)coder;
@end

NS_ASSUME_NONNULL_END
