//
//  ObjectA.m
//  TEObjc_Runtime
//
//  Created by offcn_Terry on 2019/11/27.
//  Copyright © 2019 offcn_Terry. All rights reserved.
//

#import "ObjectA.h"
#import "NSObject+JSONExtension.h"
@interface ObjectA()
@property (nonatomic, readwrite) NSString *title;
@property (nonatomic, readwrite) NSInteger count;
@end

@implementation ObjectA

- (id)initWithCoder:(NSCoder *)aDecoder{
    
    self = [super init];
    if (self) {
        // 调用封装好的自动归档方法
        [self initAllPropertiesWithCoder:aDecoder];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    
    // 调用封装好的自动解档方法
    [self encodeAllPropertiesWithCoder:aCoder];
}

@end
