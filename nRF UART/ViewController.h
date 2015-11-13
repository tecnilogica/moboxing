//
//  ViewController.h
//  nRF UART
//
//  Created by Ole Morten on 1/11/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UARTPeripheral.h"

@interface ViewController : UIViewController <UITextFieldDelegate, CBCentralManagerDelegate, UARTPeripheralDelegate>
{
    NSTimer *countdownTimer;
    int hitCounter, countdown;
    long centsPerHit;
    UIView *progressBar;
    NSDate *lastReading;
    NSUserDefaults *defaults;
}

#define COUNTDOWNLIMIT 30
#define BARX 20
#define BARY 558
#define BARW 728
#define BARH 70
#define TIMESCALE 1
#define INTERVAL_TO_IGNORE 70
#define FORCE_TO_IGNORE 300

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UITextView *consoleTextView;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UILabel *counterLabel;
@property (weak, nonatomic) IBOutlet UILabel *countdownLabel;
@property (weak, nonatomic) IBOutlet UIImageView *hitImage;
@property (weak, nonatomic) IBOutlet UILabel *totalCounterLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalMoneyLabel;
@property (weak, nonatomic) IBOutlet UIButton *fullResetButton;

- (IBAction)connectButtonPressed:(id)sender;
- (IBAction)resetButtonPressed:(id)sender;
- (IBAction)infoButtonPressed:(id)sender;
- (IBAction)fullResetButtonPressed:(id)sender;
@end

















