//
//  Utility.h
//  QiChargerController
//
//  Created by ANG on 2017/12/5.
//  Copyright © 2017年 ANG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utility : NSObject

+ (NSData *)converthexStrToNSData:(NSString *)hexStr;
+ (NSString *)convertDataToHexStr:(NSData *)data;
+ (NSString*)runPyhtonScript:(NSString*)cmd;

@end
