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

#import "HRSViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"
#import "AppUtilities.h"
#import "CorePlot-CocoaTouch.h"
#import "HelpViewController.h"


@interface HRSViewController ()
{
    NSMutableArray *hrValues;
    NSMutableArray *downSampledValues;
    NSMutableArray *analysisValues;
    NSMutableArray *analysisValues2;
    NSMutableArray *smoothingValues;
    NSMutableArray *derivativeValues;
    NSMutableArray *derivativeSumValues;
    
    int samplingCounter;
    
    int plotWindow;
    
    int plotYMaxRange, plotYMinRange, maxHR, minHR;
    int plotXInterval, plotYInterval;
    int LEDonSeconds, LEDoffSeconds, LEDduration;
    int referenceVoidValue;
    int baseResistanceValue, rollingPeakResistance;
    float mHrmValue;
    int voidBuffer;
    int derivativeCounter;
    int downSampleCount;
    int downSamplingCounter;
    float stdDeviation;
    float noiseThresholdValue;
    int LEDstatusCounter1;
    int LEDstatusCounter2;
    int movingAvgCount;
    int closedLoopInterval;
    
    NSString *turnonLED;
    NSString *turnoffLED;
    NSString *prevPeripheral;
    
    NSNumber *downSampledPoint;
    NSNumber *differential;

    NSArray *paths;
    NSString *documentsDirectory;
    NSFileManager *fileManager;
    NSFileManager *VoidfileManager;
    NSString *fileName;
    NSString *VoidfileName;
    NSFileHandle *fileHandle;
    
    NSDate *void1;
    NSDate *void2;
    NSDate *void3;
    
    BOOL isBluetoothON;
    BOOL isMasterLEDON;
    BOOL prevLEDstatus;
    BOOL isDeviceConnected;
    BOOL isBackButtonPressed;
    
    BOOL isDayTime;
    BOOL isClosedLoopON;
    BOOL isClosedLoopSwitchON;
        
    CBUUID *HR_Service_UUID;
    CBUUID *HR_Measurement_Characteristic_UUID;
    CBUUID *HR_Location_Characteristic_UUID;
    CBUUID *Battery_Service_UUID;
    CBUUID *Battery_Level_Characteristic_UUID;
    CBUUID *dfuService_UUID;
    CBUUID *dfuControl_Point_Characteristic_UUID;
    CBUUID *dfuPacket_Characteristic_UUID;
}

@property CPTScatterPlot *linePlot;
@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property (nonatomic, strong) CPTGraph *graph;

@property CPTScatterPlot *analysisPlot;
@property (nonatomic, strong) CPTGraphHostingView *hostView2;
@property (nonatomic, strong) CPTGraph *graph2;

@property CPTScatterPlot *analysisPlot2;
@property (nonatomic, strong) CPTGraphHostingView *hostView3;
@property (nonatomic, strong) CPTGraph *graph3;

@property (strong, nonatomic) CBPeripheral *hrPeripheral;

@end

@implementation HRSViewController
@synthesize bluetoothManager;
@synthesize backgroundImage;
@synthesize verticalLabel;
@synthesize battery;

@synthesize deviceName;
@synthesize dayNight;
@synthesize LEDonTime;
@synthesize LEDoffTime;
@synthesize noiseThreshold;
@synthesize voidHour;
@synthesize referenceVoid;
@synthesize stdValue;

@synthesize stdText;
@synthesize LEDonText;
@synthesize LEDoffText;
@synthesize noiseThresholdText;
@synthesize VoidHourText;
@synthesize referenceVoidText;
@synthesize closedLoopStatus;
@synthesize connectButton;
@synthesize hrValue;
@synthesize hrLocation;

@synthesize hostView;
@synthesize hostView2;
@synthesize hostView3;

@synthesize hrPeripheral;
@synthesize LEDswitch;
@synthesize closedLoopSwitch;

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        HR_Service_UUID = [CBUUID UUIDWithString:hrsServiceUUIDString];
        HR_Measurement_Characteristic_UUID = [CBUUID UUIDWithString:hrsHeartRateCharacteristicUUIDString];
        HR_Location_Characteristic_UUID = [CBUUID UUIDWithString:hrsSensorLocationCharacteristicUUIDString];
        Battery_Service_UUID = [CBUUID UUIDWithString:batteryServiceUUIDString];
        Battery_Level_Characteristic_UUID = [CBUUID UUIDWithString:batteryLevelCharacteristicUUIDString];
    }
    return self;
}

-(NSString *)showCurrentTime
{
    NSDate * now = [NSDate date];
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *timeString = [outputFormatter stringFromDate:now];
    return timeString;
}

-(NSString *)timeStamp
{
    NSDate * now1 = [NSDate date];
    NSDateFormatter *outputFormatter1 = [[NSDateFormatter alloc] init];
    [outputFormatter1 setDateFormat:@"HH:mm:ss"];
    NSString *currentTime = [outputFormatter1 stringFromDate:now1];
    return currentTime;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.setNeedsLayout;
    self.view.layoutIfNeeded;
    turnonLED = @"1";
    turnoffLED = @"2";
    isBluetoothON = NO;
    isMasterLEDON = NO;
    isDeviceConnected = NO;
    isBackButtonPressed = NO;
    hrPeripheral = nil;
    isDayTime = NO;
    isClosedLoopON = NO;
    isClosedLoopSwitchON = NO;
    movingAvgCount = 60;
    baseResistanceValue = 255;
    rollingPeakResistance = 0;
    referenceVoidValue = 100;
    
    samplingCounter = 0;
    downSampleCount = 15;
    downSamplingCounter = 0;
    plotWindow = 1800;
    
    LEDonText.tag = 100;
    LEDoffText.tag = 101;
    stdText.tag = 201;
    noiseThresholdText.tag = 301;
    VoidHourText.tag = 401;
    referenceVoidText.tag = 501;
    
    hrValues = [[NSMutableArray alloc]init];
    downSampledValues = [[NSMutableArray alloc]init];
    analysisValues = [[NSMutableArray alloc]init];
    analysisValues2 = [[NSMutableArray alloc]init];
    smoothingValues = [[NSMutableArray alloc]init];
    derivativeValues = [[NSMutableArray alloc]init];
    derivativeSumValues = [[NSMutableArray alloc]init];
    
    downSampledPoint = 0;
    differential = 0;
    
    voidBuffer = 0;
    derivativeCounter = 0;
    stdDeviation = 8;
    noiseThresholdValue = 5;
    
    plotYMaxRange = 260;
    plotYMinRange = 0;
    LEDstatusCounter1 = 0;
    LEDstatusCounter2 = 0;
    
    plotYInterval = 300;
    closedLoopInterval = 3600;
    
    [self initLinePlot];
    [self initAnalysisPlot];
    [self initAnalysisPlot2];
    [self setDayNight];
    
    //file initialize
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if(textField.tag == 100)
    {
        LEDonSeconds = [textField.text intValue]*60;
        [LEDonTime setText:[NSString stringWithFormat:@"On : %d min", [textField.text intValue]]];
        LEDonText.text = @"";
    }
    else if(textField.tag == 101)
    {
        LEDoffSeconds = [textField.text intValue]*60;
        [LEDoffTime setText:[NSString stringWithFormat:@"Off : %d min", [textField.text intValue]]];
        LEDoffText.text = @"";
    }
    else if(textField.tag == 201) {
        stdDeviation = [textField.text floatValue];
        [stdValue setText:[NSString stringWithFormat:@"Standard Dev. : %.2f", [textField.text floatValue]]];
        stdText.text = @"";
    }
    else if(textField.tag == 301) {
        noiseThresholdValue = [textField.text floatValue];
        [noiseThreshold setText:[NSString stringWithFormat:@"Noise Threshold : %.2f", [textField.text floatValue]]];
        noiseThresholdText.text = @"";
        NSLog(@"Number of Averaging Points: %d", movingAvgCount);
    }
    else if(textField.tag == 401) {
        closedLoopInterval = [textField.text intValue];
        [voidHour setText:[NSString stringWithFormat:@"Interval (s) : %d", [textField.text intValue]]];
        VoidHourText.text = @"";
    }
    else if(textField.tag == 501) {
        referenceVoidValue = [textField.text intValue];
        [referenceVoid setText:[NSString stringWithFormat:@"Void Threshold : %d", [textField.text intValue]]];
        referenceVoidText.text = @"";
    }
    
    
    NSLog(@"Interval Set to %d seconds", closedLoopInterval);
    
    [textField resignFirstResponder];
    return YES;
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"viewWillDisappear");
    if (hrPeripheral != nil && isBackButtonPressed)
    {
        [bluetoothManager cancelPeripheralConnection:hrPeripheral];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear");
    isBackButtonPressed = YES;
}

- (IBAction)connectOrDisconnectClicked
{
    if (hrPeripheral != nil)
    {
        prevPeripheral = nil;
        NSLog(@"Reset previous peripheral name");
        [bluetoothManager cancelPeripheralConnection:hrPeripheral];
        [self clearUI];
    }
}


-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
    return ![identifier isEqualToString:@"scan"] || hrPeripheral == nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scan"])
    {
        NSLog(@"prepareForSegue scan");
        // Set this contoller as scanner delegate
        ScannerViewController *controller = (ScannerViewController *)segue.destinationViewController;
        controller.filterUUID = HR_Service_UUID;
        controller.previousPeripheral = prevPeripheral;
        controller.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        NSLog(@"prepareForSegue help");
        isBackButtonPressed = NO;
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [AppUtilities getHRSHelpText];
    }
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    NSLog(@"appDidEnterBackground");
    [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"You are still connected to %@ sensor. It will collect data also in background.",self.hrPeripheral.name]];
}

-(void)appDidEnterForeground:(NSNotification *)_notification
{
    NSLog(@"appDidEnterForeground");
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

#pragma mark HRM Graph methods

-(void)initLinePlot
{
    //Initialize and display Graph (x and y axis lines)
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.graphView.bounds];
    self.hostView = [[CPTGraphHostingView alloc] initWithFrame:self.graphView.bounds];
    self.hostView.hostedGraph = self.graph;
    [self.graphView addSubview:hostView];
    
    //apply styling to Graph
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
    
    //set graph backgound area transparent
    self.graph.backgroundColor = nil;
    self.graph.fill = nil;
    self.graph.plotAreaFrame.fill = nil;
    self.graph.plotAreaFrame.plotArea.fill = nil;
    
    //This removes top and right lines of graph
    self.graph.plotAreaFrame.borderLineStyle = nil;
    //This shows x and y axis labels from 0 to 1
    self.graph.plotAreaFrame.masksToBorder = NO;
    
    // set padding for graph from Left and Bottom
    self.graph.paddingBottom = 30;
    self.graph.paddingLeft = 0;
    self.graph.paddingRight = 0;
    self.graph.paddingTop = 0;
    
    //Define x and y axis range
    // x-axis from 0 to 100
    // y-axis from 0 to 300
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = NO;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0)
                                                    length:CPTDecimalFromInt(plotWindow)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(plotYMinRange)
                                                    length:CPTDecimalFromInt(plotYMaxRange)];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    
    NSNumberFormatter *axisLabelFormatter = [[NSNumberFormatter alloc]init];
    [axisLabelFormatter setGeneratesDecimalNumbers:NO];
    [axisLabelFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    
    //Define x-axis properties
    //x-axis intermediate interval 2
    axisSet.xAxis.majorIntervalLength = CPTDecimalFromInt(11000);
    //    axisSet.xAxis.minorTicksPerInterval = 0;
    axisSet.xAxis.minorTickLength = 0;
    axisSet.xAxis.majorTickLength = 0;
    //    axisSet.xAxis.title = @"";
    //    axisSet.xAxis.titleOffset = 25;
    axisSet.xAxis.labelFormatter = axisLabelFormatter;
    
    //Define y-axis properties
    //y-axis intermediate interval = 50;
    axisSet.yAxis.majorIntervalLength = CPTDecimalFromInt(50);
    axisSet.yAxis.minorTicksPerInterval = 0;
    axisSet.yAxis.minorTickLength = 0;
    axisSet.yAxis.majorTickLength = 0;
    axisSet.yAxis.title = @"";
    axisSet.yAxis.titleOffset = 30;
    axisSet.yAxis.labelFormatter = axisLabelFormatter;
    
    
    //Define line plot and set line properties
    self.linePlot = [[CPTScatterPlot alloc] init];
    self.linePlot.dataSource = self;
    self.linePlot.identifier = @"Line Plot";
    [self.graph addPlot:self.linePlot toPlotSpace:plotSpace];
    
    //set line plot style
    CPTMutableLineStyle *lineStyle = [self.linePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth = 1;
    lineStyle.lineColor = [CPTColor blackColor];
    self.linePlot.dataLineStyle = lineStyle;
    
    CPTMutableLineStyle *symbolineStyle = [CPTMutableLineStyle lineStyle];
    symbolineStyle.lineColor = [CPTColor blackColor];
    CPTPlotSymbol *symbol = [CPTPlotSymbol ellipsePlotSymbol];
    symbol.fill = [CPTFill fillWithColor:[CPTColor blackColor]];
    symbol.lineStyle = symbolineStyle;
    symbol.size = CGSizeMake(0.1f, 0.1f);
    self.linePlot.plotSymbol = symbol;
    
    //set graph grid lines
    CPTMutableLineStyle *gridLineStyle = [[CPTMutableLineStyle alloc] init];
    gridLineStyle.lineColor = [CPTColor grayColor];
    gridLineStyle.lineWidth = 0.5;
    axisSet.xAxis.majorGridLineStyle = gridLineStyle;
    axisSet.yAxis.majorGridLineStyle = gridLineStyle;
}



-(void)initAnalysisPlot
{
    //Initialize and display Graph (x and y axis lines)
    self.graph2 = [[CPTXYGraph alloc] initWithFrame:self.analysisView.bounds];
    self.hostView2 = [[CPTGraphHostingView alloc] initWithFrame:self.analysisView.bounds];
    self.hostView2.hostedGraph = self.graph2;
    [self.analysisView addSubview:hostView2];
    
    //apply styling to Graph
    [self.graph2 applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
    
    //set graph backgound area transparent
    self.graph2.backgroundColor = nil;
    self.graph2.fill = nil;
    self.graph2.plotAreaFrame.fill = nil;
    self.graph2.plotAreaFrame.plotArea.fill = nil;
    
    //This removes top and right lines of graph
    self.graph2.plotAreaFrame.borderLineStyle = nil;
    //This shows x and y axis labels from 0 to 1
    self.graph2.plotAreaFrame.masksToBorder = NO;
    
    // set padding for graph from Left and Bottom
    self.graph2.paddingBottom = 30;
    self.graph2.paddingLeft = 0;
    self.graph2.paddingRight = 0;
    self.graph2.paddingTop = 0;
    
    //Define x and y axis range
    // x-axis from 0 to 100
    // y-axis from 0 to 300
    CPTXYPlotSpace *plotSpace2 = (CPTXYPlotSpace *)self.graph2.defaultPlotSpace;
    plotSpace2.allowsUserInteraction = NO;
//    plotSpace2.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0)
//                                                    length:CPTDecimalFromInt(plotWindow)];
//    plotSpace2.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(-25)
//                                                    length:CPTDecimalFromInt(30)];
    plotSpace2.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0)
                                                    length:CPTDecimalFromInt(plotWindow)];
    plotSpace2.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(plotYMinRange)
                                                    length:CPTDecimalFromInt(plotYMaxRange)];
    
    CPTXYAxisSet *axisSet2 = (CPTXYAxisSet *)self.graph2.axisSet;
    
    NSNumberFormatter *axisLabelFormatter2 = [[NSNumberFormatter alloc]init];
    [axisLabelFormatter2 setGeneratesDecimalNumbers:NO];
    [axisLabelFormatter2 setNumberStyle:NSNumberFormatterDecimalStyle];
    
    
    //Define x-axis properties
    //x-axis intermediate interval 2
    axisSet2.xAxis.majorIntervalLength = CPTDecimalFromInt(11000);
    axisSet2.xAxis.minorTickLength = 0;
    axisSet2.xAxis.majorTickLength = 0;
    //    axisSet.xAxis.title = @"";
    //    axisSet.xAxis.titleOffset = 25;
    axisSet2.xAxis.labelFormatter = axisLabelFormatter2;
    
    //Define y-axis properties
    axisSet2.yAxis.majorIntervalLength = CPTDecimalFromInt(50);
    axisSet2.yAxis.minorTicksPerInterval = 0;
    axisSet2.yAxis.minorTickLength = 0;
    axisSet2.yAxis.majorTickLength = 0;
    axisSet2.yAxis.title = @"";
    axisSet2.yAxis.titleOffset = 30;
    axisSet2.yAxis.labelFormatter = axisLabelFormatter2;
    
    
    //Define line plot and set line properties
    self.analysisPlot = [[CPTScatterPlot alloc] init];
    self.analysisPlot.dataSource = self;
    self.analysisPlot.identifier = @"Analysis Plot";
    [self.graph2 addPlot:self.analysisPlot toPlotSpace:plotSpace2];
    
    //set line plot style
    CPTMutableLineStyle *lineStyle2 = [self.analysisPlot.dataLineStyle mutableCopy];
    lineStyle2.lineWidth = 1;
    lineStyle2.lineColor = [CPTColor blackColor];
    self.analysisPlot.dataLineStyle = lineStyle2;
    
    CPTMutableLineStyle *symbolineStyle2 = [CPTMutableLineStyle lineStyle];
    symbolineStyle2.lineColor = [CPTColor blackColor];
    CPTPlotSymbol *symbol2 = [CPTPlotSymbol ellipsePlotSymbol];
    symbol2.fill = [CPTFill fillWithColor:[CPTColor blackColor]];
    symbol2.lineStyle = symbolineStyle2;
    symbol2.size = CGSizeMake(0.1f, 0.1f);
    self.analysisPlot.plotSymbol = symbol2;
    
    //set graph grid lines
    CPTMutableLineStyle *gridLineStyle2 = [[CPTMutableLineStyle alloc] init];
    gridLineStyle2.lineColor = [CPTColor grayColor];
    gridLineStyle2.lineWidth = 0.5;
    axisSet2.xAxis.majorGridLineStyle = gridLineStyle2;
    axisSet2.yAxis.majorGridLineStyle = gridLineStyle2;
    
}

-(void)initAnalysisPlot2
{
    //Initialize and display Graph (x and y axis lines)
    self.graph3 = [[CPTXYGraph alloc] initWithFrame:self.analysisView2.bounds];
    self.hostView3 = [[CPTGraphHostingView alloc] initWithFrame:self.analysisView2.bounds];
    self.hostView3.hostedGraph = self.graph3;
    [self.analysisView2 addSubview:hostView3];
    
    //apply styling to Graph
    [self.graph3 applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
    
    //set graph backgound area transparent
    self.graph3.backgroundColor = nil;
    self.graph3.fill = nil;
    self.graph3.plotAreaFrame.fill = nil;
    self.graph3.plotAreaFrame.plotArea.fill = nil;
    
    //This removes top and right lines of graph
    self.graph3.plotAreaFrame.borderLineStyle = nil;
    //This shows x and y axis labels from 0 to 1
    self.graph3.plotAreaFrame.masksToBorder = NO;
    
    // set padding for graph from Left and Bottom
    self.graph3.paddingBottom = 30;
    self.graph3.paddingLeft = 0;
    self.graph3.paddingRight = 0;
    self.graph3.paddingTop = 0;
    
    //Define x and y axis range
    // x-axis from 0 to 100
    // y-axis from 0 to 300
    CPTXYPlotSpace *plotSpace3 = (CPTXYPlotSpace *)self.graph3.defaultPlotSpace;
    plotSpace3.allowsUserInteraction = NO;
    plotSpace3.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0)
                                                     length:CPTDecimalFromInt(plotWindow)];
    plotSpace3.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(-10)
                                                     length:CPTDecimalFromInt(15)];
    
    CPTXYAxisSet *axisSet3 = (CPTXYAxisSet *)self.graph3.axisSet;
    
    NSNumberFormatter *axisLabelFormatter3 = [[NSNumberFormatter alloc]init];
    [axisLabelFormatter3 setGeneratesDecimalNumbers:NO];
    [axisLabelFormatter3 setNumberStyle:NSNumberFormatterDecimalStyle];
    
    
    //Define x-axis properties
    //x-axis intermediate interval 2
    axisSet3.xAxis.majorIntervalLength = CPTDecimalFromInt(plotWindow);
    //    axisSet.xAxis.minorTicksPerInterval = 0;
    axisSet3.xAxis.minorTickLength = 0;
    axisSet3.xAxis.majorTickLength = 0;
    //    axisSet.xAxis.title = @"";
    //    axisSet.xAxis.titleOffset = 25;
    axisSet3.xAxis.labelFormatter = axisLabelFormatter3;
    
    //Define y-axis properties
    axisSet3.yAxis.majorIntervalLength = CPTDecimalFromInt(3);
    axisSet3.yAxis.minorTicksPerInterval = 0;
    axisSet3.yAxis.minorTickLength = 0;
    axisSet3.yAxis.majorTickLength = 0;
    axisSet3.yAxis.title = @"";
    axisSet3.yAxis.titleOffset = 30;
    axisSet3.yAxis.labelFormatter = axisLabelFormatter3;
    
    
    //Define line plot and set line properties
    self.analysisPlot2 = [[CPTScatterPlot alloc] init];
    self.analysisPlot2.dataSource = self;
    self.analysisPlot2.identifier = @"Analysis Plot2";
    [self.graph3 addPlot:self.analysisPlot2 toPlotSpace:plotSpace3];
    
    //set line plot style
    CPTMutableLineStyle *lineStyle3 = [self.analysisPlot2.dataLineStyle mutableCopy];
    lineStyle3.lineWidth = 1;
    lineStyle3.lineColor = [CPTColor blackColor];
    self.analysisPlot2.dataLineStyle = lineStyle3;
    
    CPTMutableLineStyle *symbolineStyle3 = [CPTMutableLineStyle lineStyle];
    symbolineStyle3.lineColor = [CPTColor blackColor];
    CPTPlotSymbol *symbol3 = [CPTPlotSymbol ellipsePlotSymbol];
    symbol3.fill = [CPTFill fillWithColor:[CPTColor blackColor]];
    symbol3.lineStyle = symbolineStyle3;
    symbol3.size = CGSizeMake(0.1f, 0.1f);
    self.analysisPlot2.plotSymbol = symbol3;
    
    //set graph grid lines
    CPTMutableLineStyle *gridLineStyle3 = [[CPTMutableLineStyle alloc] init];
    gridLineStyle3.lineColor = [CPTColor grayColor];
    gridLineStyle3.lineWidth = 0.5;
    axisSet3.xAxis.majorGridLineStyle = gridLineStyle3;
    axisSet3.yAxis.majorGridLineStyle = gridLineStyle3;
    
}

-(void)updatePlotSpace
{
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    //    [plotSpace scaleToFitPlots:@[self.linePlot]];
    plotSpace.allowsUserInteraction = NO;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0)
                                                    length:CPTDecimalFromInt(plotWindow)];            // Xrange
//    maxHR = [[hrValues valueForKeyPath:@"@max.intValue"] intValue];
//    minHR = [[hrValues valueForKeyPath:@"@min.intValue"] intValue];
//    maxHR = maxHR + 20;
//    minHR = minHR - 20;
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(50)
                                                    length:CPTDecimalFromInt(plotYMaxRange)];
//    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(minHR)
//                                                    length:CPTDecimalFromInt(maxHR)];

    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    axisSet.xAxis.majorIntervalLength = CPTDecimalFromInt(plotWindow);
}


-(void)updatePlotSpace2
{
    CPTXYPlotSpace *plotSpace2 = (CPTXYPlotSpace *)self.graph2.defaultPlotSpace;
    plotSpace2.allowsUserInteraction = NO;
    plotSpace2.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0)
                                                    length:CPTDecimalFromInt(plotWindow)];            // Xrange
    plotSpace2.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(50)
                                                    length:CPTDecimalFromInt(plotYMaxRange)];
    
    CPTXYAxisSet *axisSet2 = (CPTXYAxisSet *)self.graph2.axisSet;
    axisSet2.xAxis.majorIntervalLength = CPTDecimalFromInt(plotWindow);
}

-(void)updatePlotSpace3
{
    CPTXYPlotSpace *plotSpace3 = (CPTXYPlotSpace *)self.graph3.defaultPlotSpace;
    plotSpace3.allowsUserInteraction = NO;
    plotSpace3.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0)
                                                     length:CPTDecimalFromInt(plotWindow)];            // Xrange
    plotSpace3.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(50)
                                                     length:CPTDecimalFromInt(plotYMaxRange)];
    
    CPTXYAxisSet *axisSet3 = (CPTXYAxisSet *)self.graph3.axisSet;
    axisSet3.xAxis.majorIntervalLength = CPTDecimalFromInt(plotWindow);
}


-(void)addHRValueToGraph:(int)data
{
    if ([hrValues count] < plotWindow) {            // Xrange
        [hrValues insertObject:[NSNumber numberWithFloat:mHrmValue] atIndex:0];
    }
    else {
        [hrValues insertObject:[NSNumber numberWithFloat:mHrmValue] atIndex:0];
        [hrValues removeLastObject];
    }
    [self.graph reloadData];
}


-(void)addHRValueToGraph2:(float)data
{
    if ([analysisValues count] < plotWindow) {            // Xrange
        [analysisValues insertObject:[NSNumber numberWithFloat:data] atIndex:0];
        // NSLog(@"Added to analysisValues : %f", data);
    }
    else {
        [analysisValues insertObject:[NSNumber numberWithFloat:data] atIndex:0];
        [analysisValues removeLastObject];
    }
    [self.graph2 reloadData];
}

-(void)addHRValueToGraph3:(float)data
{
    if ([analysisValues2 count] < plotWindow) {            // Xrange
        [analysisValues2 insertObject:[NSNumber numberWithFloat:data] atIndex:0];
        // NSLog(@"Added to analysisValues : %f", data);
    }
    else {
        [analysisValues2 insertObject:[NSNumber numberWithFloat:data] atIndex:0];
        [analysisValues2 removeLastObject];
    }
    [self.graph3 reloadData];
}


#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [hrValues count];
}



-(NSArray *)numbersForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndexRange:(NSRange)indexRange
{
    NSArray *nums = nil;
    
    switch ( fieldEnum ) {
        case CPTScatterPlotFieldX:
                nums = [NSMutableArray arrayWithCapacity:indexRange.length];
                for ( NSUInteger i = indexRange.location; i < NSMaxRange(indexRange); i++ ) {
                    [(NSMutableArray *)nums addObject :[NSDecimalNumber numberWithUnsignedInteger:plotWindow-i]];            // Xrange
                }
            break;
            
        case CPTScatterPlotFieldY:
            if ( [(NSString *)plot.identifier isEqualToString:@"Line Plot"] ) {
                nums = [hrValues objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:indexRange]];
            }
            else if ( [(NSString *)plot.identifier isEqualToString:@"Analysis Plot"] ){
                nums = [analysisValues objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:indexRange]];
            }
            else if ( [(NSString *)plot.identifier isEqualToString:@"Analysis Plot2"] ){
                nums = [analysisValues2 objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:indexRange]];
            }
            break;
        default:
            break;
    }
    
    return nums;
}


#pragma mark Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    bluetoothManager = manager;
    bluetoothManager.delegate = self;
    
    // The sensor has been selected, connect to it
    hrPeripheral = peripheral;
    hrPeripheral.delegate = self;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
    [bluetoothManager connectPeripheral:hrPeripheral options:options];
}

#pragma mark Central Manager delegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        // TODO
    }
    else
    {
        // TODO
        NSLog(@"Bluetooth not ON");
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [deviceName setText:peripheral.name];
        [connectButton setTitle:@"DISCONNECT" forState:UIControlStateNormal];
        //[hrValues removeAllObjects];
        //[analysisValues removeAllObjects];
        //[analysisValues2 removeAllObjects];
        //[smoothingValues removeAllObjects];
        [fileHandle closeFile];
        NSLog(@"Connected to %@", peripheral.name);
        prevPeripheral = peripheral.name;
        NSLog(@"Saved peripheral name is %@", prevPeripheral);
    });
    //Following if condition display user permission alert for background notification
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // Peripheral has connected. Discover required services
    //[hrPeripheral discoverServices:@[HR_Service_UUID,Battery_Service_UUID]];
    [hrPeripheral discoverServices:nil];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [AppUtilities showAlert:@"Error" alertMessage:@"Connecting to the peripheral failed. Try again"];
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        hrPeripheral = nil;
        
        [self clearUI];
    });
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if ([prevPeripheral length] != 0) {
        NSLog(@"Reconnect peripheral");
//        [segue.identifier isEqualToString:@"scan"]
//        [self prepareForSegue:@"scan" sender:sender];
//        [segue perform];
        [self performSegueWithIdentifier:@"scan" sender:self];
        
    }
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        hrPeripheral = nil;
        
        if ([AppUtilities isApplicationStateInactiveORBackground]) {
            [AppUtilities showBackgroundNotification:[NSString stringWithFormat:@"%@ peripheral is disconnected.",peripheral.name]];
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
}

#pragma mark Peripheral delegate methods

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices");
    if (!error) {
        NSLog(@"services discovered %lu",(unsigned long)[peripheral.services count] );
        for (CBService *hrService in peripheral.services) {
            NSLog(@"service discovered: %@",hrService.UUID);
            if ([hrService.UUID isEqual:HR_Service_UUID]) {
                NSLog(@"HR service found");
                [hrPeripheral discoverCharacteristics:nil forService:hrService];
                
                fileName = [NSString stringWithFormat:@"%@/%@_%@.txt", documentsDirectory, prevPeripheral, [self showCurrentTime]];
                VoidfileName = [NSString stringWithFormat:@"%@/%@_Voids.txt", documentsDirectory, prevPeripheral];
                
                fileManager = [NSFileManager defaultManager];
                VoidfileManager = [NSFileManager defaultManager];
                
                if (![fileManager fileExistsAtPath:fileName]) {
                    BOOL success = [[NSString stringWithFormat:@""] writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:&error];
                }
                
                if (![VoidfileManager fileExistsAtPath:VoidfileName]) {
                    BOOL success = [[NSString stringWithFormat:@"%@\n", prevPeripheral] writeToFile:VoidfileName atomically:YES encoding:NSUTF8StringEncoding error:&error];
                }
                
                NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileName];
            }
        }
    }
    else {
        NSLog(@"error in discovering services on device: %@",hrPeripheral.name);
    }
}


-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        if ([service.UUID isEqual:HR_Service_UUID]) {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID]) {
                    NSLog(@"HR Measurement characteritsic is found");
                    [hrPeripheral setNotifyValue:YES forCharacteristic:characteristic ];
                }
                else if ([characteristic.UUID isEqual:HR_Location_Characteristic_UUID]) {
                    NSLog(@"HR Position characteristic is found");
                    [hrPeripheral setNotifyValue:YES forCharacteristic:characteristic ];
                    self.hrLocationCharacteristic = characteristic;
                    
                    
                }
            }
        }
    }
    
    else {
        NSLog(@"error in discovering characteristic on device: %@",hrPeripheral.name);
    }
}


-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!error) {
            if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID]) {
                [self addHRValueToGraph:[self decodeHRValue:characteristic.value]];
                [self setDayNight];

                // If # of hrValues < movingAvgCount (=60), append values
                // hrValues = array of 1800 raw data points - for plotting
                // smoothingValues = array of 60 raw data points
                // downSampledValues = array of 10 [average of smoothingValues] added every downSampleCouunt (=15) samples
                
                BOOL isPrelimVoid = 0;
                BOOL isRealVoid = 0;
                
                // During the first movingAvgCount (=60) samples
                if ([hrValues count] < movingAvgCount) {
                    [self addHRValueToGraph3:(int) 0];
                    [smoothingValues insertObject:[NSNumber numberWithFloat:mHrmValue] atIndex:0];
                    
                    if (downSamplingCounter >= downSampleCount) {
                        [downSampledValues insertObject:[smoothingValues valueForKeyPath:@"@avg.self"] atIndex:0];
                        downSampledPoint = [smoothingValues valueForKeyPath:@"@avg.self"];
                        downSamplingCounter = 0;
                    }
                    else {
                        downSamplingCounter++;
                    }
                }
                
                else {
                    [smoothingValues insertObject:[NSNumber numberWithFloat:mHrmValue] atIndex:0];
                    [smoothingValues removeLastObject];
                    
                    // Every 15 counts, downsample averaged value
                    if (downSamplingCounter >= downSampleCount) {
                        downSamplingCounter = 0;
                        
                        // Time before looking for voids = downsampling (=15) * voidBuffer(=20) => 300seconds = 5min
                        if ((voidBuffer != 0) & (voidBuffer <20)) {
                            voidBuffer++;
                            NSLog(@"Void Buffer : %d", voidBuffer);
                        }
                        else if (voidBuffer == 20) {
                            voidBuffer = 0;
                            NSLog(@"Void Buffer : %d", voidBuffer);
                        }
                        
                        downSampledPoint = [smoothingValues valueForKeyPath:@"@avg.self"];
                        differential = [NSNumber numberWithFloat:([downSampledPoint floatValue] - [downSampledValues[0] floatValue])];
                        
                        // Add value to downSampledValues array (size = 10)
                        if ([downSampledValues count] < 10) {
                            [downSampledValues insertObject:[smoothingValues valueForKeyPath:@"@avg.self"] atIndex:0];
                        }
                        else {
                            [downSampledValues insertObject:[smoothingValues valueForKeyPath:@"@avg.self"] atIndex:0];
                            [downSampledValues removeLastObject];
                            rollingPeakResistance = [[smoothingValues valueForKeyPath:@"@max.self"] intValue];
                        }
                        
                        // Save differentials in derivativeValues array (size = 13)
                        if ([derivativeValues count] < 13) {
                            [derivativeValues insertObject:differential atIndex:0];
                        }
                        else {
                            [derivativeValues insertObject:differential atIndex:0];
                            [derivativeValues removeLastObject];

                        }
                        
                        // Preliminary void if sumofthree dev < -2 * std; then isVOID = 1

                        if ([self sumOfThreeDiff] < -2 * stdDeviation) {
                            isPrelimVoid = 1;
                            NSLog(@"Preliminary void detected");
                            
                            if (([self isFalseVoid] == 0) && (voidBuffer == 0) && ((rollingPeakResistance - baseResistanceValue) < referenceVoidValue)) {
                                isRealVoid = 1;
                                NSLog(@"Real void detected");
                            }
                        }

                        
                        if (isRealVoid == 1) {

                            // Record as void in Void file
                            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:VoidfileName];
                            [fileHandle seekToEndOfFile];
                            
                            NSString *str = [NSString stringWithFormat:@"%@\n", [self showCurrentTime]];
                            NSData *textData = [str dataUsingEncoding:NSUTF8StringEncoding];
                            [fileHandle writeData:textData];
                            [fileHandle closeFile];
                            
                            // Reset base value for resistance
                            baseResistanceValue = 255;
                            
                            // ** Record Void information
                            voidBuffer = 1;
                            
                            if (void1 == NULL) {
                                void1 = [NSDate date];
                            }
                            else if (void2 == NULL) {
                                void2 = [NSDate date];
                            }
                            else if (void3 == NULL) {
                                void3 = [NSDate date];
                            }
                            else {
                                void1 = void2;
                                void2 = void3;
                                void3 = [NSDate date];
                            
                                NSTimeInterval twoVoids = [void3 timeIntervalSinceDate:void1];
                                NSInteger interval = twoVoids;
                            
                                NSLog(@"Interval: %d", (int)interval);
                            
                                if ((interval < closedLoopInterval) && isClosedLoopSwitchON == 1 && isClosedLoopON == 0) {
                                NSLog(@"Initiate Closed Loop");
                                    isClosedLoopON = 1;
                                    LEDonSeconds = 120*60;
                                    [LEDonTime setText:[NSString stringWithFormat:@"On : %d min", 120]];
                                    LEDoffSeconds = 1200*60;
                                    [LEDoffTime setText:[NSString stringWithFormat:@"Off : %d min", 1200]];
                                    [self.LEDswitch setOn:YES animated:YES];
                                    isMasterLEDON = TRUE;
                                    [hrPeripheral writeValue:[self->turnonLED dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.hrLocationCharacteristic type:CBCharacteristicWriteWithoutResponse];
                                    prevLEDstatus = YES;
                                    closedLoopStatus.text = @"Status: ON";
                                    
                                    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:VoidfileName];
                                    [fileHandle seekToEndOfFile];
                                    
                                    NSString *str = [NSString stringWithFormat:@"%@ Activated Close Loop\n", [self showCurrentTime]];
                                    NSData *textData = [str dataUsingEncoding:NSUTF8StringEncoding];
                                    [fileHandle writeData:textData];
                                    [fileHandle closeFile];
                                }
                                else if ((isClosedLoopSwitchON == 0) || ((interval > closedLoopInterval) && (isClosedLoopON == 1))) {
                                    NSLog(@"Deactivate Closed Loop");
                                    isClosedLoopON = 0;
                                    [self.LEDswitch setOn:NO animated:YES];
                                    isMasterLEDON = FALSE;
                                    [hrPeripheral writeValue:[self->turnoffLED dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.hrLocationCharacteristic type:CBCharacteristicWriteWithoutResponse];
                                    prevLEDstatus = NO;
                                    closedLoopStatus.text = @"Status: OFF";
                                    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:VoidfileName];
                                    [fileHandle seekToEndOfFile];
                                    
                                    NSString *str = [NSString stringWithFormat:@"%@ Deactivated Close Loop\n", [self showCurrentTime]];
                                    NSData *textData = [str dataUsingEncoding:NSUTF8StringEncoding];
                                    [fileHandle writeData:textData];
                                    [fileHandle closeFile];
                                }
                            }
                        }
                    }
                    downSamplingCounter++;
                    [self addHRValueToGraph3:[differential floatValue]];
                }
                
                // save data to file here
                // need to add prelim void, false void, real void
                
                fileName = [NSString stringWithFormat:@"%@/%@_%@.txt", documentsDirectory, prevPeripheral, [self showCurrentTime]];
                NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileName];
                [fileHandle seekToEndOfFile];
                
                NSString *str = [NSString stringWithFormat:@"%.02f\t%.02f\t%d\t%d\n", [downSampledPoint doubleValue], [differential doubleValue], isPrelimVoid, isRealVoid];
                
                NSData *textData = [str dataUsingEncoding:NSUTF8StringEncoding];
                [fileHandle writeData:textData];
                [fileHandle closeFile];

                
            }
        }
        else {
            NSLog(@"error in update HRM value");
        }
    });
}



-(int) decodeHRValue:(NSData *)data
{
    const uint8_t *value = [data bytes];
    fileName = [NSString stringWithFormat:@"%@/%@_%@.txt", documentsDirectory, prevPeripheral, [self showCurrentTime]];
    NSError *error = nil;
    
    if (![fileManager fileExistsAtPath:fileName]) {
        BOOL success = [[NSString stringWithFormat:@""] writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileName];
    [fileHandle seekToEndOfFile];
    
    
    [hrValue setText:[NSString stringWithFormat:@"%d", value[0]]];
   
    BOOL currentLEDstatus = value[1];
    
    if ((currentLEDstatus == YES) & (prevLEDstatus == NO)) {
        LEDstatusCounter1++;
        if (LEDstatusCounter1 > 10) {
            prevLEDstatus = YES;
            LEDstatusCounter1 = 0;
        }
    }
    
    if ((currentLEDstatus == NO) & (prevLEDstatus == YES)) {
        LEDstatusCounter2++;
        if (LEDstatusCounter2 > 10) {
            prevLEDstatus = NO;
            LEDstatusCounter2 = 0;
        }
    }
    
    
    
    
    if (currentLEDstatus == YES) {
        LEDonTime.textColor = [UIColor colorWithRed:(0.f) green:(0.f) blue:(0.f) alpha:1.0];
        LEDoffTime.textColor = [UIColor colorWithRed:(200/255.f) green:(200/255.f) blue:(200/255.f) alpha:1.0];
    }
    else if (currentLEDstatus == NO) {
        LEDoffTime.textColor = [UIColor colorWithRed:(0.f) green:(0.f) blue:(0.f) alpha:1.0];
        LEDonTime.textColor = [UIColor colorWithRed:(200/255.f) green:(200/255.f) blue:(200/255.f) alpha:1.0];
    }

    
    
    
    if (isMasterLEDON == YES) {
        if ((LEDduration > LEDonSeconds) & (prevLEDstatus == YES)) {
            [hrPeripheral writeValue:[self->turnoffLED dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.hrLocationCharacteristic type:CBCharacteristicWriteWithoutResponse];
            LEDduration = 0;
            prevLEDstatus = NO;
            NSLog(@"Turned off LED");
        }
        else if((LEDduration > LEDoffSeconds) & (prevLEDstatus == NO)) {
            [hrPeripheral writeValue:[self->turnonLED dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.hrLocationCharacteristic type:CBCharacteristicWriteWithoutResponse];
            LEDduration = 0;
            prevLEDstatus = YES;
            NSLog(@"Turned on LED");
        }
        else {
            LEDduration++;
//            NSLog(@"LED DURATION: %d", LEDduration);
        }
    }

//    int randomNum = arc4random() % 250;
//    mHrmValue = randomNum;
//    NSString *str = [NSString stringWithFormat:@"%@\t%d\t%hhu\t%d\t%d\t", [self timeStamp], randomNum, value[1], isClosedLoopSwitchON, isClosedLoopON];

    mHrmValue = value[0];
    NSString *str = [NSString stringWithFormat:@"%@\t%hhu\t%hhu\t%d\t%d\t", [self timeStamp], value[0], value[1], isClosedLoopSwitchON, isClosedLoopON];
    NSData *textData = [str dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandle writeData:textData];
    [fileHandle closeFile];
    
    if (baseResistanceValue > value[0]) {
        baseResistanceValue = mHrmValue;
    }
    
    return 0;
}

-(float) sumOfThreeDiff
{
    float a = [[derivativeValues objectAtIndex:0] floatValue];
    float f;
    if ([derivativeValues count] > 1) {
        float b = [[derivativeValues objectAtIndex:1] floatValue];
        f = a+b;
    }
    if ([derivativeValues count] > 2) {
        float b = [[derivativeValues objectAtIndex:1] floatValue];
        float c = [[derivativeValues objectAtIndex:2] floatValue];
        f = a+b+c;
    }
    return f;
}

-(BOOL) isFalseVoid
{
    float sum = 0;
    float count = 0;
    
    if ([derivativeValues count] > 12) {
        for (int t = 2; t<=12; t++) {
            if ([[derivativeValues objectAtIndex:t] floatValue] > 0) {
                sum += [[derivativeValues objectAtIndex:t] floatValue];
                count++;
            }
        }
    }
    else {
        count = 1;
    }
    
    float avg = sum/count;

    if (avg > noiseThresholdValue) {
        return 1;
        
    }
    else {
        return 0;
    }
}


- (void) setDayNight
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *datenow = [NSDate date];
    NSDateComponents *datenowComponents = [calendar components:NSCalendarUnitHour fromDate:datenow];
    NSInteger currentHour = datenowComponents.hour;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSDate *sixAM = [formatter dateFromString:@"06:00:00"];
    NSDate *sixPM = [formatter dateFromString:@"18:00:00"];
    NSDateComponents *AMcomponents = [calendar components:NSCalendarUnitHour fromDate:sixAM];
    NSDateComponents *PMcomponents = [calendar components:NSCalendarUnitHour fromDate:sixPM];
    NSInteger AM = AMcomponents.hour;
    NSInteger PM = PMcomponents.hour;
    
    if((currentHour >= AM) & (currentHour < PM)) {
        [dayNight setText:[NSString stringWithFormat:@"Day"]];
        isDayTime = 1;
    }
    else {
        [dayNight setText:[NSString stringWithFormat:@"Night"]];
        isDayTime = 0;
    }
}

- (void) clearUI
{
    deviceName.text = @"SPARC (T)";
    LEDonTime.text = @"On : 0 min";
    LEDonSeconds = 0;
    LEDoffTime.text = @"Off : 0 min";
    noiseThreshold.text = @"Noise Threshold : 5";
    noiseThresholdValue = 5;
    voidHour.text = @"Interval (s) : 3600";
    movingAvgCount = 60;
    closedLoopInterval = 3600;
    referenceVoid.text = @"Void Volume : 10";
    referenceVoidValue = 100;
    LEDoffSeconds = 0;
    LEDduration = 0;
    LEDstatusCounter1 = 0;
    LEDstatusCounter1 = 0;
    prevLEDstatus = 0;
    isMasterLEDON = NO;
    [self.LEDswitch setOn:NO animated:YES];
    LEDoffTime.textColor = [UIColor colorWithRed:(0.f) green:(0.f) blue:(0.f) alpha:1.0];
    LEDonTime.textColor = [UIColor colorWithRed:(200/255.f) green:(200/255.f) blue:(200/255.f) alpha:1.0];
    
    hrValue.text = @"-";
    [hrValues removeAllObjects];
    [downSampledValues removeAllObjects];
    [analysisValues removeAllObjects];
    [smoothingValues removeAllObjects];
    [derivativeValues removeAllObjects];
    [derivativeSumValues removeAllObjects];
    
    samplingCounter = 0;
    voidBuffer = 0;
    stdDeviation = 8;
    [stdValue setText:[NSString stringWithFormat:@"Standard Dev. : %d", (int) 8]];
    [noiseThreshold setText:[NSString stringWithFormat:@"Noise Threshold : %d", (int) 5]];
    
    void1 = NULL;
    void2 = NULL;
    void3 = NULL;

}


- (IBAction)LEDswitchPressed:(id)sender {
    if (isMasterLEDON == false) {
        [self.LEDswitch setOn:YES animated:YES];
        isMasterLEDON = TRUE;
        [hrPeripheral writeValue:[self->turnonLED dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.hrLocationCharacteristic type:CBCharacteristicWriteWithoutResponse];
        prevLEDstatus = YES;
        NSLog(@"Master LED control turned : %id", isMasterLEDON);
    }
    else {
        [self.LEDswitch setOn:NO animated:YES];
        isMasterLEDON = FALSE;
        NSLog(@"Master LED control turned : %id", isMasterLEDON);
        prevLEDstatus = NO;
        [hrPeripheral writeValue:[self->turnoffLED dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.hrLocationCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}


- (IBAction)closedLoopSwitchPressed:(id)sender {
    if (isClosedLoopSwitchON == false) {
        [self.closedLoopSwitch setOn:YES animated:YES];
        isClosedLoopSwitchON = TRUE;
        NSLog(@"Closed Loop status turned : %id", isClosedLoopSwitchON);
    }
    else {
        [self.closedLoopSwitch setOn:NO animated:YES];
        isClosedLoopSwitchON = FALSE;
        NSLog(@"Closed Loop status turned : %id", isClosedLoopSwitchON);
    }
}

@end
