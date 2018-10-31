/*
 * Copyright (c) 2015, Nordic Semiconductor
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ScannerDelegate.h"
#import "CorePlot-CocoaTouch.h"

@interface HRSViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, UITextFieldDelegate, ScannerDelegate, CPTPlotDataSource>

@property (strong, nonatomic) CBPeripheral *bluetoothPeripheral;

@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UILabel *verticalLabel;
@property (weak, nonatomic) IBOutlet UIButton *battery;
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UILabel *closedLoopStatus;
@property (weak, nonatomic) IBOutlet UILabel *dayNight;
@property (weak, nonatomic) IBOutlet UILabel *LEDonTime;
@property (weak, nonatomic) IBOutlet UILabel *LEDoffTime;
@property (weak, nonatomic) IBOutlet UILabel *noiseThreshold;
@property (weak, nonatomic) IBOutlet UILabel *voidHour;
@property (weak, nonatomic) IBOutlet UILabel *referenceVoid;
@property (weak, nonatomic) IBOutlet UILabel *stdValue;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UILabel *hrValue;
@property (weak, nonatomic) IBOutlet UILabel *hrLocation;
@property (weak, nonatomic) IBOutlet UILabel *trigTime;
@property (weak, nonatomic) IBOutlet UISwitch *LEDswitch;
@property (weak, nonatomic) IBOutlet UISwitch *closedLoopSwitch;

@property (weak, nonatomic) IBOutlet UIView *graphView;
@property (weak, nonatomic) IBOutlet UIView *analysisView;
@property (weak, nonatomic) IBOutlet UIView *analysisView2;

@property (strong, nonatomic) IBOutlet UITextField *LEDonText;
@property (strong, nonatomic) IBOutlet UITextField *LEDoffText;
@property (strong, nonatomic) IBOutlet UITextField *noiseThresholdText;
@property (strong, nonatomic) IBOutlet UITextField *VoidHourText;
@property (strong, nonatomic) IBOutlet UITextField *referenceVoidText;
@property (strong, nonatomic) IBOutlet UITextField *stdText;


@property (strong, nonatomic)CBCharacteristic *hrLocationCharacteristic;

- (IBAction)connectOrDisconnectClicked;

@end
