//
//  ViewController.m
//  QiChargerController
//
//  Created by ANG on 2017/12/5.
//  Copyright © 2017年 ANG. All rights reserved.
//

#import <ORSSerial/ORSSerial.h>
#import "ViewController.h"
#import "Utility.h"
@interface ViewController()<ORSSerialPortDelegate, NSUserNotificationCenterDelegate>
@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
//B431
@property (nonatomic, strong) ORSSerialPort *serialDevice;
@property (weak) IBOutlet NSPopUpButton *uartPort;
@property (weak) IBOutlet NSButton *uartOpenButton;
@property (nonatomic, copy) NSString *pythonScriptPath;
@property (unsafe_unretained) IBOutlet NSTextView *logText;
@property (weak) IBOutlet NSTextField *railVtext;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addSerialPortList];
    
    //package Qi cmd python script path
    self.pythonScriptPath = [[NSBundle mainBundle] pathForResource:@"cmdPackage.py" ofType:nil];
    
}

- (void)writeToQiChargerWithRegister:(NSString *)Register nargs:(NSString *)nargs value:(NSString *)value{
    
    NSString *cmd = @"";
    usleep(100000);
    if (value.length > 0) {
        //get cmd package
        cmd = [Utility runPyhtonScript:[NSString stringWithFormat:@"python %@ %@ %@ %@",self.pythonScriptPath,Register,nargs,value]];
    }
    else{
        cmd = [Utility runPyhtonScript:[NSString stringWithFormat:@"python %@ %@ %@",self.pythonScriptPath,Register,nargs]];
    }
    //hexstring to data
    NSData *data = [Utility converthexStrToNSData:cmd];
    [self sendMessage:data];
}

- (IBAction)openPort:(NSButton *)sender {
    if ([sender.title isEqualToString:@"OPEN"]) {
        [self.serialDevice open];
        if ([self.serialDevice isOpen]) {
            NSLog(@"uart open");
            self.uartOpenButton.title = @"CLOSE";
            //enter debug mode
            [self writeToQiChargerWithRegister:@"0x05" nargs:@"1" value:@"1"];
        }
    }
    else{
        [self.serialDevice close];
        usleep(100000);
        if (![self.serialDevice isOpen]) {
            self.uartOpenButton.title = @"OPEN";
        }
    }
}



- (IBAction)setRailV:(NSButton *)sender {
    
    [self writeToQiChargerWithRegister:@"0x0A" nargs:@"2" value:self.railVtext.stringValue];
}

- (IBAction)enablePWM:(NSButton *)sender {

    [self writeToQiChargerWithRegister:@"0x0D" nargs:@"0" value:@""];

}
- (IBAction)readRailV:(NSButton *)sender {

    [self writeToQiChargerWithRegister:@"0x09" nargs:@"0" value:@""];

}


- (IBAction)readRailC:(NSButton *)sender {
    
    [self writeToQiChargerWithRegister:@"0x0F" nargs:@"0" value:@""];

}


- (IBAction)readFW:(NSButton *)sender {

    [self writeToQiChargerWithRegister:@"0x28" nargs:@"0" value:@""];

}

- (void)addSerialPortList{
    NSArray *ports = [NSArray arrayWithArray:self.serialPortManager.availablePorts];
    NSLog(@"%@",ports);
    [self.uartPort removeAllItems];
    for (int i = 0; i < ports.count; i++) {
        NSString *portName  = [NSString stringWithFormat:@"%@",ports[i]];
        if (![portName containsString:@"Bluetooth"]) {
            [self.uartPort addItemWithTitle:portName];
        }
    }
}

- (void)sendMessage:(NSData*)data{
    [self.serialDevice sendData:data];
    usleep(100000);
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    
}
- (void)serialPortWasRemovedFromSystem:(nonnull ORSSerialPort *)serialPort {

}

- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    //data to hexstring
    NSString *hexStr = [Utility convertDataToHexStr:data];
    NSString *string = @"";
    if (hexStr.length < 10) {
        string = @"ERROR\n";
    }
    else{
        NSMutableArray *mutableArr = [NSMutableArray arrayWithCapacity:10];
        for (int idx = 0; idx+2 <= hexStr.length; idx+=2) {
            NSRange range = NSMakeRange(idx, 2);
            NSString* ch = [hexStr substringWithRange:range];
            [mutableArr addObject:ch];
        }
        NSString *value = @"";
        for (int i = 0; i < [mutableArr[2] intValue]; i++) {
            value = [NSString stringWithFormat:@"%@%@",value,mutableArr[i+3]];
        }
        unsigned long intValue = strtoul([value UTF8String],0,16);
        
        string = [NSString stringWithFormat:@"%@\n",[NSString stringWithFormat:@"%lu",intValue]];
        if ([mutableArr[1] containsString:@"a8"]) {
            string = [NSString stringWithFormat:@"%lu.%lu.%lu\n",(intValue >> 12) & 0xf, (intValue >> 8) & 0xf, (intValue >> 4) & 0x0f];
        }
        if (intValue == 1) {
            string = @"OK\n";
        }
    }
    
    [self.logText.textStorage.mutableString appendString:string];
    [self.logText scrollRangeToVisible:NSMakeRange([[self.logText string] length], 0)];
    [self.logText setNeedsDisplay:YES];
    
}
- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
}

#pragma mark - lazy functions


- (ORSSerialPortManager *)serialPortManager{
    if (!_serialPortManager) {
        _serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
    }
    return _serialPortManager;
}

- (ORSSerialPort *)serialDevice{
    if (!_serialDevice) {
        _serialDevice = [ORSSerialPort serialPortWithPath:[NSString stringWithFormat:@"/dev/cu.%@",[self.uartPort selectedItem].title]];
        _serialDevice.baudRate = @115200;
        _serialDevice.delegate = self;
    }
    return _serialDevice;
}
@end
