//
//  Utility.m
//  QiChargerController
//
//  Created by ANG on 2017/12/5.
//  Copyright © 2017年 ANG. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+ (NSData *)converthexStrToNSData:(NSString *)hexStr
{
    NSMutableData* data = [NSMutableData data];
    for (int idx = 0; idx+2 <= hexStr.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* ch = [hexStr substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:ch];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}



+ (NSString*)runPyhtonScript:(NSString*)cmd
{
    @synchronized(self.class)
    {
        @try
        {
            if ([cmd rangeOfString:@"cd"].location!=NSNotFound && [cmd rangeOfString:@"&& pwd"].location==NSNotFound)
            {
                cmd=[NSString stringWithFormat:@"%@ && pwd",cmd];
            }
            
            NSTask *task=[[NSTask alloc] init];
            
            [task setLaunchPath:@"/bin/bash"];
            [task setArguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
            
            NSPipe *pipe=[NSPipe pipe];
            
            [task setStandardInput:[NSPipe pipe]];
            [task setStandardOutput: pipe];
            [task setStandardError: pipe];
            
            NSFileHandle *file=[pipe fileHandleForReading];
            [task launch];
            [task waitUntilExit];
            
            NSString *output=[[NSString alloc]initWithData:[file readDataToEndOfFile] encoding:NSASCIIStringEncoding];
            
            return [output componentsSeparatedByString:@"\n"][0];;
        }
        @catch(NSException *e)
        {
            return [NSString stringWithFormat:@"%@",e];
        }
    }
}

+ (NSString *)convertDataToHexStr:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}



@end
