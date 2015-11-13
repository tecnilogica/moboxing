//
//  ViewController.m
//  nRF UART
//
//  Created by Ole Morten on 1/11/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "ViewController.h"

typedef enum
{
    IDLE = 0,
    SCANNING,
    CONNECTED,
} ConnectionState;

typedef enum
{
    LOGGING,
    RX,
    TX,
} ConsoleDataType;



@interface ViewController ()
@property CBCentralManager *cm;
@property ConnectionState state;
@property UARTPeripheral *currentPeripheral;
@end

@implementation ViewController
@synthesize cm = _cm;
@synthesize currentPeripheral = _currentPeripheral;


- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults boolForKey:@"USERDEFAULT_IS_INITIALIZED"]) {
        [defaults setBool:YES forKey:@"USERDEFAULT_IS_INITIALIZED"];
        [defaults setInteger:0 forKey:@"TOTAL_HIT_COUNTER"];
        [defaults setInteger:2 forKey:@"CENTS_PER_HIT"];
        [defaults synchronize];
    }
    
    centsPerHit = [defaults integerForKey:@"CENTS_PER_HIT"];

    self.consoleTextView.hidden = YES;
    self.fullResetButton.hidden = YES;
    self.connectButton.hidden = YES;
    
    [self addTextToConsole:@"Did start application" dataType:LOGGING];

    progressBar  = [[UIView alloc] initWithFrame:CGRectMake(BARX, BARY, BARW, BARH)];
    progressBar.backgroundColor = [UIColor colorWithRed:0.023 green:0.784 blue:0.674 alpha:1.0];
    progressBar.layer.zPosition = -10;
    [self.view addSubview:progressBar];
    
    hitCounter = 0;
    [self updateHitCounterLabel];
    [self stopCountdown];
    self.resetButton.hidden = YES;
    
    lastReading = [NSDate date];
    
}



- (IBAction)connectButtonPressed:(id)sender
{
   
    switch (self.state) {
        case IDLE:
            
            self.state = SCANNING;
            
            NSLog(@"Started scan ...");
            [self.connectButton setTitle:@"Buscando ..." forState:UIControlStateNormal];
            
            hitCounter = 0;
            [self updateHitCounterLabel];
            
            [self.cm scanForPeripheralsWithServices:@[UARTPeripheral.uartServiceUUID] options:@{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:NO]}];
            break;
            
        case SCANNING:
            self.state = IDLE;

            NSLog(@"Stopped scan");
            [self.connectButton setTitle:@"Conectar el guante" forState:UIControlStateNormal];

            [self.cm stopScan];
            break;
            
        case CONNECTED:
            NSLog(@"Disconnect peripheral %@", self.currentPeripheral.peripheral.name);
            [self.cm cancelPeripheralConnection:self.currentPeripheral.peripheral];
            
            break;
    }
}



- (IBAction)resetButtonPressed:(id)sender {
   
    hitCounter = 0;
    [self updateHitCounterLabel];
    
    [self stopCountdown];
    
}



- (IBAction)infoButtonPressed:(id)sender {
    
    self.consoleTextView.hidden = !self.consoleTextView.hidden;
    self.fullResetButton.hidden = self.consoleTextView.hidden;
    self.connectButton.hidden = self.consoleTextView.hidden;
    
}



- (IBAction)fullResetButtonPressed:(id)sender {
    
    [defaults setInteger:0 forKey:@"TOTAL_HIT_COUNTER"];
    [defaults synchronize];

    [self resetButtonPressed:sender];
    
}



- (void) didReceiveData:(NSString *)string
{
    NSDate *currentDate = [NSDate date];
    double milliInterval = [lastReading timeIntervalSinceNow] * -1000;
    lastReading = currentDate;
    
    NSLog(@"ms interval %f", milliInterval);
    
    if (milliInterval >= INTERVAL_TO_IGNORE && [string intValue] >= FORCE_TO_IGNORE) {
    
        if (hitCounter==0) {
            [self startCountdown];
        }
        
        if ([countdownTimer isValid]) {
            
            hitCounter++;
            self.hitImage.alpha = 1;
            [UIView animateWithDuration:0.2 animations:^{
                self.hitImage.alpha = 0.0;
            }];
            
            [defaults setInteger:[defaults integerForKey:@"TOTAL_HIT_COUNTER"]+1 forKey:@"TOTAL_HIT_COUNTER"];
            [defaults synchronize];
            
            [self updateHitCounterLabel];
        
        
        }

        [self addTextToConsole:string dataType:RX];

    
    }

}



- (void) addTextToConsole:(NSString *) string dataType:(ConsoleDataType) dataType
{
    NSString *direction;
    switch (dataType)
    {
        case RX:
            direction = @"RX";
            break;
            
        case TX:
            direction = @"TX";
            break;
            
        case LOGGING:
            direction = @"Log";
    }
    
    NSDateFormatter *formatter;
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss.SSS"];
    
    self.consoleTextView.text = [self.consoleTextView.text stringByAppendingFormat:@"[%@] %@: %@\n",[formatter stringFromDate:[NSDate date]], direction, string];
    
//    @try {
//        
//        NSRange bottom = NSMakeRange(self.consoleTextView.text.length-1, self.consoleTextView.text.length);
//        [self.consoleTextView scrollRangeToVisible:bottom];
//    }
//    
//    @catch (NSException *exception) {
//
//        NSLog(@"eporeproeprepoereporeproeproeroper");
//        
//    }
//    
}



- (void) startCountdown
{
    countdown = COUNTDOWNLIMIT / TIMESCALE;
    [self.countdownLabel setText:[NSString stringWithFormat:@"%d", (int)(countdown * TIMESCALE)]];
    
    progressBar.hidden = NO;
    progressBar.frame = CGRectMake(BARX, BARY, BARW, BARH);

    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:TIMESCALE
                                                      target:self
                                                    selector:@selector(advanceTimer:)
                                                    userInfo:nil
                                                     repeats:YES];
}



- (void)stopCountdown
{

    progressBar.hidden = YES;
    self.hitImage.alpha = 0;

    [countdownTimer invalidate];
    [self.countdownLabel setText:@""];
}



- (void) advanceTimer:(NSTimer *) timer
{
    
    countdown--;
    
    [self.countdownLabel setText:[NSString stringWithFormat:@"%d", (int)(countdown * TIMESCALE)]];
    progressBar.frame = CGRectMake(BARX, BARY, BARW * countdown / (COUNTDOWNLIMIT / TIMESCALE), BARH);
    
    if (countdown<0) {
        [self stopCountdown];
    }
    
}



- (void) updateHitCounterLabel
{

    [self.counterLabel setText:[NSString stringWithFormat:@"%d", hitCounter]];
    [self.totalCounterLabel setText:[NSString stringWithFormat:@"%ld", (long)[defaults integerForKey:@"TOTAL_HIT_COUNTER"]]];
    [self.totalMoneyLabel setText:[NSString stringWithFormat:@"%.2f€", [defaults integerForKey:@"TOTAL_HIT_COUNTER"] * centsPerHit / 100.0]];

}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark BLE Code

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        [self.connectButton setEnabled:YES];
    }
    
}



- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Did discover peripheral %@", peripheral.name);
    [self.cm stopScan];
    
    self.currentPeripheral = [[UARTPeripheral alloc] initWithPeripheral:peripheral delegate:self];
    
    [self.cm connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];
}



- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Did connect peripheral %@", peripheral.name);

    [self addTextToConsole:[NSString stringWithFormat:@"Did connect to %@", peripheral.name] dataType:LOGGING];
    
    self.state = CONNECTED;
    [self.connectButton setTitle:@"Desconectar" forState:UIControlStateNormal];
    self.resetButton.hidden = NO;
    
    if ([self.currentPeripheral.peripheral isEqual:peripheral])
    {
        [self.currentPeripheral didConnect];
    }

    
}



- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Did disconnect peripheral %@", peripheral.name);
    
    [self addTextToConsole:[NSString stringWithFormat:@"Did disconnect from %@, error code %ld", peripheral.name, (long)error.code] dataType:LOGGING];
    
    self.state = IDLE;
    [self.connectButton setTitle:@"Conectar el guante" forState:UIControlStateNormal];
    self.resetButton.hidden = YES;
    
    if ([self.currentPeripheral.peripheral isEqual:peripheral])
    {
        [self.currentPeripheral didDisconnect];
    }
}



- (void) didReadHardwareRevisionString:(NSString *)string
{
    [self addTextToConsole:[NSString stringWithFormat:@"Hardware revision: %@", string] dataType:LOGGING];
}
@end
