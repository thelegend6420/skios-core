//
//  SKGraphForResults.m
//  SKCore
//
//  Copyright (c) 2011-2014 SamKnows Limited. All rights reserved.
//

#import "SKGraphForResults.h"

@interface SKGraphForResults()
@property CPTGraphHostingView *mpHostView;
@property CPTPlot *mpCorePlot;
@property CPTGraph *mpGraph;
@property NSDictionary *mpLocalDateDictForTestType;
@property NSString *testName; // e.g. voip_jitter

@property DATERANGE_1w1m3m1y mDateFilter;

@end

@implementation SKGraphForResults

@synthesize mpHostView;
@synthesize mpCorePlot;
@synthesize mpGraph;
@synthesize mpLocalDateDictForTestType;

@synthesize mDateFilter;

- (id)init
{
  self = [super init];
  if (self) {
  }
  return self;
}

-(void) setHidden:(BOOL)inHidden {
  
  self.mpHostView.hidden = inHidden;
  
}

-(BOOL) hidden {
  return mpHostView.hidden;
}

//
//
//

//
// CorePlot experiment!
//

static const NSTimeInterval oneDay = 24.0 * 60.0 * 60.0;

-(CPTPlot*)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated WithDateFilter:(DATERANGE_1w1m3m1y)inDateFilter
{
  // 2a. create the graph
  //CGRect theBounds = layerHostingView.bounds;
  //CGRect theFrame = layerHostingView.frame;
  CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:layerHostingView.bounds];
  self.mpGraph = graph;
  
  layerHostingView.hostedGraph = graph;
  
  // The default padding on the graph itself (not the plot area frame) is 20 pixels on each side.
  // http://stackoverflow.com/questions/10086283/coreplot-on-ios-how-to-remove-the-default-padding-so-the-chart-fills-the-view
  graph.paddingLeft = 0.0;
  graph.paddingTop = 0.0;
  graph.paddingRight = 0.0;
  graph.paddingBottom = 0.0;
  
  // The PADDING REGION etc. are relative to the width/height we specify later (e.g. 100/100);
  // they are resolution independent.
  // To leave space for the axes AND for plot markers - you MUST set these values big enough!
  graph.plotAreaFrame.paddingTop    = 25.0;
  graph.plotAreaFrame.paddingBottom = 20.0;
  graph.plotAreaFrame.paddingLeft   = 40.0;
  graph.plotAreaFrame.paddingRight  = 15.0;
  graph.plotAreaFrame.cornerRadius  = 3.0;
  
  // Set theme, if any supplied.
  if (theme != nil) {
    //CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [graph applyTheme:theme];
  }
  
  // Set up plot space - this is an area that is automatically scaled to fit the viewport.
  CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
  double timeInterval = [self.mpCorePlotDates[self.mpCorePlotDates.count-1] timeIntervalSinceDate:self.mpCorePlotDates[0]];
  if (inDateFilter == DATERANGE_1w1m3m1y_ONE_DAY) {
    timeInterval = oneDay;
  }
  plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0) length:CPTDecimalFromFloat(timeInterval)];
  plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(self.corePlotMinValue) length:CPTDecimalFromFloat(self.corePlotMaxValue + 0.01)];
  // Experiment with a bit more space, to allow the point markers to draw!
  // plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0) length:CPTDecimalFromFloat(timeInterval * 1.05)];
  //plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(self.corePlotMinValue) length:CPTDecimalFromFloat(self.corePlotMaxValue * 1.05 + 0.01)];
  
 
  //
  // Create the chart!
   //
  CPTScatterPlot *aaplPlot = [[CPTScatterPlot alloc] init];
  aaplPlot.identifier = graph.title;
  aaplPlot.dataSource = self;
  //aaplPlot.delegate = self;
  
  // Set up line style etc.
  CPTMutableLineStyle *theLineStyle = [CPTMutableLineStyle new];
  CPTColor *lineColor = [CPTColor colorWithComponentRed:(((float)0x2b)/255.0)
                                                  green:(((float)0x6d)/255.0)
                                                   blue:(((float)0xa3)/255.0)
                                                  alpha:1.0];
  
  theLineStyle.lineColor = lineColor; // [CPTColor greenColor]; // ]lightGrayColor];
  theLineStyle.lineWidth = 1.5f;
  aaplPlot.dataLineStyle = theLineStyle;
  
  // Apply grid/axes!
  // Line styles
  CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
  // Set this to e.g. 1 to show x/y axis lines.
  // Set this to 0 to hide the x/y axis lines.
  // Always show the axes, as it looks tidier.
  //axisLineStyle.lineWidth = 0.0;
  axisLineStyle.lineWidth = 1.0;
  //axisLineStyle.lineCap   = kCGLineCapRound;
  axisLineStyle.lineColor = [CPTColor lightGrayColor];
  
  CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
  majorGridLineStyle.lineWidth = 0.75;
  CPTColor *gridLineColor = [CPTColor colorWithComponentRed:0.90
                                                      green:0.90
                                                       blue:0.90
                                                      alpha:0.8];
  majorGridLineStyle.lineColor = gridLineColor;
  majorGridLineStyle.dashPattern = CPTLinearBlendingMode;
//  if (inDateFilter == DATERANGE_1w1m3m1y_ONE_DAY) {
//    // Hide the vertical lines!
//    majorGridLineStyle.lineColor = [CPTColor clearColor];
//  }
  
  //    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
  //    minorGridLineStyle.lineWidth = 0.25;
  //    minorGridLineStyle.lineColor = [CPTColor blueColor];
  
  // Text styles
  CPTMutableTextStyle *yAxisLabelTextStyle = [CPTMutableTextStyle textStyle];
  yAxisLabelTextStyle.fontName = @"Helvetica";
  yAxisLabelTextStyle.fontSize = 10.0;
  yAxisLabelTextStyle.textAlignment = CPTTextAlignmentLeft;
  
  CPTMutableTextStyle *yAxisLabelClearTextStyle = [CPTMutableTextStyle textStyle];
  yAxisLabelClearTextStyle.fontName = @"Helvetica";
  yAxisLabelClearTextStyle.fontSize = 10.0;
  yAxisLabelClearTextStyle.color = [CPTColor clearColor];
  yAxisLabelClearTextStyle.textAlignment = CPTTextAlignmentLeft;

  
  CPTMutableTextStyle *xAxisTitleTextStyle = [CPTMutableTextStyle textStyle];
  xAxisTitleTextStyle.fontName = @"Helvetica";
  xAxisTitleTextStyle.fontSize = 10.0;
  
  // Axes
  CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
  
  // Label y axis with a fixed interval policy
  CPTXYAxis *y          = axisSet.yAxis;
  y.separateLayers              = NO;
  y.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0); // Have the tick starting from this value.
  y.majorIntervalLength         = CPTDecimalFromDouble(100.0/3.0); // Have the tick every "this many" items.
  // x.minorTicksPerInterval       = 4; // Comment-out: have no minor ticks
  y.tickDirection               = CPTSignNone;
  y.axisLineStyle               = axisLineStyle;
  y.majorTickLength             = 0.0; // Hide the major ticks!
  y.majorTickLineStyle          = axisLineStyle;
  //y.majorGridLineStyle          = majorGridLineStyle;
  y.minorTickLength             = 0.0; // Hide the minor ticks!
  // y.minorGridLineStyle          = minorGridLineStyle;
  y.labelOffset = +15.0; // A negative value moves the label values TO THE RIGHT, positive to LEFT (!)
  y.labelAlignment =  CPTAlignmentLeft; // This simply doesn't seem to work!
  y.labelingPolicy  = CPTAxisLabelingPolicyAutomatic;
  y.labelTextStyle = yAxisLabelTextStyle;
  
  double daysPerBar = 1.0;
  switch (inDateFilter) {
    case DATERANGE_1w1m3m1y_ONE_WEEK:
      daysPerBar = 1.0;
      break;
      
    case DATERANGE_1w1m3m1y_ONE_MONTH:
      daysPerBar = 7.0;
      break;
      
    case DATERANGE_1w1m3m1y_THREE_MONTHS:
      daysPerBar = 14.0;
      break;
      
    case DATERANGE_1w1m3m1y_SIX_MONTHS:
      daysPerBar = 28.0;
      break;
      
    case DATERANGE_1w1m3m1y_ONE_YEAR:
      daysPerBar = 28.0*2.0;
      break;
      
    case DATERANGE_1w1m3m1y_ONE_DAY:
      // Using 24, is just too much - though might be OK on landscape!
      daysPerBar = 1.0/24.0;
//    {
//      Experiment with plotting a symbole at each data point
//      CPTPlotSymbol *googSymbol = [CPTPlotSymbol ellipsePlotSymbol];
//      CPTColor *googColor =  lineColor; // [CPTColor blueColor];
//      googSymbol.fill = [CPTFill fillWithColor:googColor];
//      CPTMutableLineStyle *googSymbolLineStyle = [CPTMutableLineStyle lineStyle];
//      googSymbolLineStyle.lineColor = googColor;
//      googSymbol.lineStyle = googSymbolLineStyle;
//      googSymbol.size = CGSizeMake(4.0f, 4.0f);
//      aaplPlot.plotSymbol = googSymbol;
//    }
      break;
      
    default:
    {
      NSString *debugString = [NSString stringWithFormat:@"%s:%d Unexpected date format", __FUNCTION__, __LINE__];
      [SKCore sAppendLogString:debugString IsError:YES];
    }
      break;
  }
  
  // Alter the numeric resolution on the Y axis, depending on the data type.
  // http://stackoverflow.com/questions/9317690/how-change-precision-of-axis-labels-in-coreplot
  NSNumberFormatter *Yformatter = [[NSNumberFormatter alloc] init];
  [Yformatter setNumberStyle:NSNumberFormatterDecimalStyle];
  y.labelFormatter = Yformatter;
  
  //NSLog(@"minFractDigits=%d", Yformatter.minimumFractionDigits);
  //NSLog(@"maxFractDigits=%d", Yformatter.maximumFractionDigits);
  
  if (([self.testName isEqualToString:@"downstream_mt"]) ||
      ([self.testName isEqualToString:@"upstream_mt"]))
  {
    y.Title = NSLocalizedString(@"Graph_Title_Mbps",nil);
    y.titleOffset                 = +1.0; // Negative moves it RIGHT, Positive moves it LEFT!
  } else if ([self.testName isEqualToString:@"latency"]) {
    y.Title = NSLocalizedString(@"Graph_Title_Ms",nil);
    y.titleOffset                 = +5.0;
  } else if ([self.testName isEqualToString:@"packetloss"]) {
    y.Title = NSLocalizedString(@"Graph_Title_Percent",nil);
    y.titleOffset                 = +5.0;  // Negative moves it RIGHT, Positive moves it LEFT!
  } else if ([self.testName isEqualToString:@"www_load"]) {
    y.Title = NSLocalizedString(@"Graph_Title_Sec",nil);
    y.titleOffset                 = +4.0;
  } else { // if ([self.testName isEqualToString:@"voip_jitter"])
    y.Title = NSLocalizedString(@"Graph_Title_Ms",nil);
    y.titleOffset                 = +5.0;
  }
  
  CPTMutableTextStyle *yAxisTitleTextStyle = [CPTMutableTextStyle textStyle];
  yAxisTitleTextStyle.fontName = @"Helvetica-Bold";
  yAxisTitleTextStyle.fontSize = 12.0;
  yAxisTitleTextStyle.textAlignment = CPTTextAlignmentLeft;
  yAxisTitleTextStyle.color = [CPTColor blackColor];
  y.titleTextStyle              = yAxisTitleTextStyle;
  
  // Convert from drawing coordinates, to plot coordinates... so that we can position the title properly!
  // Note that the offset is a movement UP!
  // http://stackoverflow.com/questions/11914613/core-plot-how-to-position-the-axis-title-for-two-y-axes-at-the-same-height
  CGRect plotAreaBounds = graph.plotAreaFrame.plotArea.bounds;
  CGPoint viewPoint = CGPointMake(plotAreaBounds.origin.x+10,
                                  plotAreaBounds.origin.y + plotAreaBounds.size.height + 20);
  NSDecimal plotPoint[2];
  [plotSpace plotPoint:plotPoint forPlotAreaViewPoint:viewPoint];
  y.titleLocation = plotPoint[CPTCoordinateY];
  y.titleRotation = M_PI*2;
  
  //
  // Create the grid!
  //
  CPTXYAxis *x          = axisSet.xAxis;
  x.separateLayers              = YES;
  x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0); // Have the tick starting from this value.
  
  x.tickDirection               = CPTSignNone;
  x.majorIntervalLength         = CPTDecimalFromDouble(oneDay * daysPerBar);
  // If we're using the 24-hour view, use a delegate to use custom labels;
  // this is because there are simply too many labels for a 24 hours of data!
  if (inDateFilter == DATERANGE_1w1m3m1y_ONE_DAY) {
    x.delegate = self;
  }
  x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
  x.axisLineStyle               = axisLineStyle;
  x.majorTickLength             = 0.0; // Hide the major ticks!
//  if (inDateFilter == DATERANGE_1w1m3m1y_ONE_DAY) {
//    x.majorTickLength             = 5.0; // For 24-hour view - show major ticks!
//  }
  x.majorTickLineStyle          = axisLineStyle;
  x.majorGridLineStyle          = majorGridLineStyle;
  x.labelTextStyle = xAxisTitleTextStyle;
  x.minorTickLength             = 0.0; // Hide the minor ticks!
  // The CPTAxisLabelingPolicyNone labeling policy does not create any labels or tick marks.
  // Use CPTAxisLabelingPolicyFixedInterval instead!
  // http://stackoverflow.com/questions/16682717/core-plot-grid-lines-dont-appear-when-labeling-policy-is-not-automatic
  x.labelingPolicy  = CPTAxisLabelingPolicyFixedInterval;
  // x.minorGridLineStyle          = minorGridLineStyle;
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  if (inDateFilter == DATERANGE_1w1m3m1y_ONE_DAY) {
    [dateFormatter setDateFormat:[SKGlobalMethods getGraphTimeFormat]];
  }
  else
  {
    [dateFormatter setDateFormat:[SKGlobalMethods getGraphDateFormat]];
  }
  CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
  timeFormatter.referenceDate = self.mpCorePlotDates[0];
  if (inDateFilter == DATERANGE_1w1m3m1y_ONE_DAY) {
    timeFormatter.referenceDate = [NSDate dateWithTimeIntervalSinceNow:-oneDay*1.0];
  }
  x.labelFormatter = timeFormatter;
  
  //
  // Now define the plot gradient to use...
  //
  
  CPTColor *areaColor = [CPTColor colorWithComponentRed:(((float)0xb8)/255.0)
                                                  green:(((float)0xd3)/255.0)
                                                   blue:(((float)0xe1)/255.0)
                                                  alpha:1.0];
  CPTColor *areaEndColor = [CPTColor colorWithComponentRed:(((float)0x6d)/255.0)
                                                     green:(((float)0xad)/255.0)
                                                      blue:(((float)0xce)/255.0)
                                                     alpha:1.0];
  
  // CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor clearColor]];
  CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:areaEndColor];
  areaGradient.angle = -90.0f;
//  if (inDateFilter == DATERANGE_1w1m3m1y_ONE_DAY) {
//    // Just do a simple plot, as we have time when there are simply no results!
//  }
//  else
  {
    // Do a plot that fills-in underneath!
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    aaplPlot.areaFill = areaGradientFill;
    // http://stackoverflow.com/questions/9351399/how-to-fill-graph-area-with-color
    //aaplPlot.areaFill = [CPTFill fillWithColor:areaColor];
    aaplPlot.areaBaseValue = CPTDecimalFromInt(0); // Defines the bottom value to fill from!
  }
  
  //
  // Finally, add the plot to the graph plot space.
  //
  [graph addPlot:aaplPlot toPlotSpace:graph.defaultPlotSpace];
  
  //
  // Override the chart layer orders so the grid lines are drawn on top of the bar in the chart.
  // The layers are listed here from the TOP first, down to the BOTTOM layer last.
  // https://groups.google.com/forum/#!topic/coreplot-discuss/Gwl23UsE_N8
  //
  double range = self.corePlotMaxValue - self.corePlotMinValue;
  if (range == 0.0) {
    // NO ITEMS - so do NOT SHOW the Y axis labels, otherwise we get all zeros up the axis!
    y.labelTextStyle = yAxisLabelClearTextStyle;
  }
  
  NSArray *chartLayers = [[NSArray alloc] initWithObjects:
                          [NSNumber numberWithInt:CPTGraphLayerTypeMajorGridLines],
                          [NSNumber numberWithInt:CPTGraphLayerTypeMinorGridLines],
                          [NSNumber numberWithInt:CPTGraphLayerTypePlots],
                          [NSNumber numberWithInt:CPTGraphLayerTypeAxisLines],
                          [NSNumber numberWithInt:CPTGraphLayerTypeAxisLabels],
                          [NSNumber numberWithInt:CPTGraphLayerTypeAxisTitles],
                          nil];
  graph.topDownLayerOrder = chartLayers;
  
  return aaplPlot;
}

//// http://stackoverflow.com/questions/9054979/core-plot-how-to-change-color-of-negative-axis-tick-labels
//-(BOOL)axis:(CPTAxis *)axis shouldUpdateAxisLabelsAtLocations:(NSSet *)locations
//{
//  //static CPTTextStyle *positiveStyle = nil;
//  //static CPTTextStyle *negativeStyle = nil;
//  
//  //NSNumberFormatter *formatter = axis.labelFormatter;
//  CGFloat labelOffset          = axis.labelOffset;
//  //NSDecimalNumber *zero        = [NSDecimalNumber zero];
//  
//  NSMutableSet *newLabels = [NSMutableSet set];
//  
//  int lLocationIndex = 0;
//  for ( NSDecimalNumber *tickLocation in locations ) {
//    
//    // Which date to use?
//    NSDate *theDate = self.mpCorePlotDates[lLocationIndex];
//    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"d/MM"];
//    
//    NSString *labelString = [dateFormatter stringFromDate:theDate];
//    
//    CPTTextLayer *newLabelLayer = [[CPTTextLayer alloc] initWithText:labelString];
//    
//    CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithContentLayer:newLabelLayer];
//    newLabel.tickLocation = tickLocation.decimalValue;
//    newLabel.offset       = labelOffset;
//    
//    [newLabels addObject:newLabel];
//    lLocationIndex++;
//  }
//  
//  axis.axisLabels = newLabels;
//  
//  return NO;
//}

-(void)extractCorePlotData {
  NSString *debugString = [NSString stringWithFormat:@"DEBUG: %s:%d", __FUNCTION__, __LINE__];
  [SKCore sAppendLogString:debugString IsError:NO];
  
  // The data points received are from the start day, to the end day.
  // However, values might not be present for any given day.
  // The way that the old graph system seemed to work, is to start from a zero value.
  // If a data point is missing, the value used is interpolated between the last received value,
  // and the next value; if no value has yet been seen, then the value remains at zero.
  
  NSDictionary *theRequest = self.mpLocalDateDictForTestType[@"request"];
  NSString *theTestName=theRequest[@"test_type"];
  if (theTestName == nil) {
    // Required for the SK App...
    NSArray *theTests = theRequest[@"tests"];
    if (theTests == nil) {
      SK_ASSERT(false);
    } else if (theTests.count == 0) {
      SK_ASSERT(false);
    } else {
      SK_ASSERT(theTests.count == 1);
      theTestName = theTests[0];
      SK_ASSERT(theTestName != nil);
    }
  }
  SK_ASSERT(theTestName != nil);
  self.testName = theTestName; // e.g. voip_jitter

  //
  // If necessary, we actually display 24-hour data!
  //
  
  if (self.mDateFilter == DATERANGE_1w1m3m1y_ONE_DAY) {
    [self extractPlotDataAveragedByHourFor24Hours:theTestName];
    
    return;
  }
  
  [self extractPlotDataAveragedByDay:theTestName];
}

- (void)extractPlotDataAveragedByHourFor24Hours:(NSString*)theTestName {
  // Use these 'point' values, which are NOT grouped at all...
  
  NSDictionary *theResults = self.mpLocalDateDictForTestType[@"results"];
  
  NSMutableArray * theNewArray = [NSMutableArray new];
  NSMutableArray * theDateArray = [NSMutableArray new];
  
  // First we first sort them in ascending order of date...
  NSMutableArray *valuesArray24 = theResults[@"24hours"];
  
  NSArray *sortedArray24 = [valuesArray24 sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    NSDictionary *theDay1 = (NSDictionary*)obj1;
    NSDictionary *theDay2 = (NSDictionary*)obj2;
    NSNumber *theStartTimeInterval1 = theDay1[@"DATE"];
    NSNumber *theStartTimeInterval2 = theDay2[@"DATE"];
    NSDate *theDate1 = [NSDate dateWithTimeIntervalSince1970:[theStartTimeInterval1 doubleValue]];
    NSDate *theDate2 = [NSDate dateWithTimeIntervalSince1970:[theStartTimeInterval2 doubleValue]];
    if ([theDate1 timeIntervalSinceDate:theDate2] < 0)
      return NSOrderedAscending;
    if ([theDate1 timeIntervalSinceDate:theDate2] > 0)
      return NSOrderedDescending;
    return NSOrderedSame;
  }];
  
#ifdef DEBUG
  NSLog(@"DEBUG: 24 hour results...:");
#endif // DEBUG
  
  // Now, group the values by HOUR!
  NSMutableArray *valuesByHour = [NSMutableArray new];
  NSMutableArray *itemsByHour = [NSMutableArray new];
  NSMutableArray *datesByHour = [NSMutableArray new];
  
  double timeIntervalForOneHour = (oneDay / 24.0);
  
  // Our dates are calculated based on "NOW"
  {
    NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:-oneDay];
    
    int hourIndex;
    for (hourIndex = 0; hourIndex < 24; hourIndex++) {
      [datesByHour addObject:[NSDate dateWithTimeInterval:((double)hourIndex) * timeIntervalForOneHour sinceDate:yesterday]];
      [itemsByHour  addObject:[NSNumber numberWithInt:0]];
      [valuesByHour addObject:[NSNumber numberWithDouble:0.0]];
    }
  }
  
  for (NSDictionary *theDay in sortedArray24) {
    NSNumber *theStartTimeInterval = theDay[@"DATE"];
    NSDate *theDate = [NSDate dateWithTimeIntervalSince1970:[theStartTimeInterval doubleValue]];
    NSNumber *theResult = theDay[@"RESULT"];
    
    // Are we in a new hour?
    // If so, save the last value before continuing!
    NSTimeInterval timeIntervalSinceStart = [theDate timeIntervalSinceDate:datesByHour[0]];
    int hourIndex = (int) (timeIntervalSinceStart / timeIntervalForOneHour);
    SK_ASSERT(hourIndex >= 0);
    SK_ASSERT(hourIndex <= 23);
    if (hourIndex < 0) {
      hourIndex = 0;
    }
    if (hourIndex > 23) {
      hourIndex = 23;
    }
    
    itemsByHour[hourIndex] = [NSNumber numberWithInt:([itemsByHour[hourIndex] intValue] + 1)];
    valuesByHour[hourIndex] = [NSNumber numberWithDouble:([valuesByHour[hourIndex] doubleValue] + [theResult doubleValue])];
  }
  
  // Now run through, and calculate the averages.
  {
    int hourIndex;
    for (hourIndex = 0; hourIndex < 24; hourIndex++) {
      if ([itemsByHour[hourIndex] intValue] > 0) {
        NSNumber *theAverage = [NSNumber numberWithDouble:([valuesByHour[hourIndex] doubleValue] / [itemsByHour[hourIndex] doubleValue])];
        valuesByHour[hourIndex] = theAverage;
      }
    }
  }
  
  // Finally, find the minimum and maximum values, for scaling the plot!
  self.corePlotMinValue = 0.0;
  //  bool bMinFound = false;
  self.corePlotMaxValue = 0.0;
  bool bMaxFound = false;
  
  {
    int hourIndex;
    for (hourIndex = 0; hourIndex < 24; hourIndex++) {
      NSDate *theDate = datesByHour[hourIndex];
      NSNumber *theResult = valuesByHour[hourIndex];
      
      if (bMaxFound == false) {
        self.corePlotMaxValue = [theResult doubleValue];
        bMaxFound = true;
      }
      
      if ([theResult doubleValue] > self.corePlotMaxValue) {
        self.corePlotMaxValue = [theResult doubleValue];
        bMaxFound = true;
      }
      
      [theNewArray addObject:theResult];
      [theDateArray addObject:theDate];
    }
  }
  
  self.mpCorePlotDataPoints = theNewArray;
  self.mpCorePlotDates = theDateArray;
}

-(void) extractPlotDataAveragedByDay:(NSString*)theTestName {
  
  NSMutableArray * theNewArray = [NSMutableArray new];
  NSMutableArray * theDateArray = [NSMutableArray new];
  
  NSDictionary *theResults = self.mpLocalDateDictForTestType[@"results"];
  
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  
  NSDictionary *theRequest = self.mpLocalDateDictForTestType[@"request"];
  NSString *theStartDateString = theRequest[@"start_date"];
  [dateFormatter setDateFormat:@"yyyy-MM-dd"];
  NSString *theEndDateString = theRequest[@"end_date"];
  //NSArray *theTests = theRequest[@"tests"];
  //NSString *theTestName= theTests[0];
  //NSArray *theTests = theRequest[@"tests"];
  
  NSDictionary *theDateValues= theResults[theTestName];
  
  NSDate *theStartDate = [dateFormatter dateFromString:theStartDateString];
  // The KEY is the DATE.
  if (theStartDate == nil) {
    SK_ASSERT(false);
    return;
  }
  
  NSString *theCheckStartDate = [dateFormatter stringFromDate:theStartDate];
  // Verify that our formatter works!
  SK_ASSERT([theCheckStartDate isEqualToString:theStartDateString]);
  
  NSDate *theEndDate = [dateFormatter dateFromString:theEndDateString];
  
  
  
  int daysBetween = [theEndDate timeIntervalSinceDate:theStartDate] / (60.0 * 60.0 * 24.0);
  // We MUST INCLUDE the actual end date.
  // For example, for one week: start date might be 01 Aug, end date might be 08 Aug ...
  // 01 02 03 04 05 06 07 08
  //   ^  ^  ^  ^  ^  ^  ^   = 7 days!!!
  //
  // 22 23 24 25 26 27 28 29
  //   ^  ^  ^  ^  ^  ^  ^
  daysBetween++;
  
  int dayIndex;
  for (dayIndex = 0; dayIndex <= daysBetween; dayIndex++) {
    
    NSDate *theTargetDate = [theStartDate dateByAddingTimeInterval:60*60*24*dayIndex];
    NSString *theTargetDateString = [dateFormatter stringFromDate:theTargetDate];
    
    if (theTargetDateString == nil) {
      SK_ASSERT(false);
      return;
    }
    
    [theDateArray addObject:theTargetDate];
    
    NSString *theNumber = [theDateValues objectForKey:theTargetDateString];
    if ( (theNumber == nil) ||
        ([theNumber isKindOfClass:[NSNull class]])
        )
    {
      // Nothing found!
      NSString *newItem = [NSString new];
      if (newItem == nil) {
        SK_ASSERT(false);
        return;
      }
      
      [theNewArray addObject:newItem];
      continue;
    }
    
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    // If you do NOT do this, it will NOT DISPLAY GRAPHS in e.g. Germany or Brazil!
    [f setDecimalSeparator:@"."];
    
    NSNumber * myNumber = [f numberFromString:theNumber];
    double value = [myNumber doubleValue];
    
    NSString *debugString = [NSString stringWithFormat:@"%s:%d dayIndex %d, EXTRACTED Date %@, value=%g", __FUNCTION__, __LINE__, dayIndex, theTargetDateString, value];
    [SKCore sAppendLogString:debugString IsError:NO];
    
    NSNumber *numberItem = [NSNumber numberWithDouble:value];
    if (numberItem == nil) {
      SK_ASSERT(false);
      return;
    }
    
    [theNewArray addObject:numberItem];
  }
  
  // To reach here, we have an array of items...
  // We must now interpolate!
  
  int theLastNonNilNumberAtIndex = -1;
  int lIndex = 0;
  int lItems = (int)theNewArray.count;
  for (lIndex = 0; lIndex < lItems; lIndex++) {
    NSObject *theObject = theNewArray[lIndex];
    
    if ([theObject isKindOfClass:[NSString class]]) {
      // This is our PLACEHOLDER!
      if (theLastNonNilNumberAtIndex == -1) {
        // Nothing we can do here!
        continue;
      }
      
      NSNumber *theNumberAtLastNonNilIndex = theNewArray[theLastNonNilNumberAtIndex];
      
      // Interpolate. Look FORWARD to the next number!
      // If none found, then simply copy forward.
      bool bLookForwardFound = false;
      
      int lLookForwardIndex;
      for (lLookForwardIndex = lIndex + 1; ; lLookForwardIndex++) {
        if (lLookForwardIndex >= lItems)
        {
          break;
        }
        
        NSObject *theLookForwardObject = theNewArray[lLookForwardIndex];
        if ([theLookForwardObject isKindOfClass:[NSNumber class]]) {
          NSNumber *theLookForwardNumber = (NSNumber*)theLookForwardObject;
          bLookForwardFound = true;
          
          // Calculate the value to use!
          double theDecimalLookForward = [theLookForwardNumber doubleValue];
          double theDecimalNumberAtLastNonNilIndex = [theNumberAtLastNonNilIndex doubleValue];
          double theInterpolatedValue = theDecimalNumberAtLastNonNilIndex + (theDecimalLookForward - theDecimalNumberAtLastNonNilIndex) * ((double)(lIndex - theLastNonNilNumberAtIndex)) / ((double)(lLookForwardIndex - theLastNonNilNumberAtIndex));
          theNewArray[lIndex] = [NSNumber numberWithDouble:theInterpolatedValue];
          break;
        }
      }
      
      if (bLookForwardFound == false) {
        theNewArray[lIndex] = theNewArray[theLastNonNilNumberAtIndex];
      }
      
    } else {
      theLastNonNilNumberAtIndex = lIndex;
    }
    
  }
  
  // Finally, find the minimum and maximum values, for scaling the plot!
  self.corePlotMinValue = 0.0;
  //  bool bMinFound = false;
  self.corePlotMaxValue = 0.0;
  bool bMaxFound = false;
  
  for (NSObject *theObject in theNewArray) {
    if ([theObject isKindOfClass:[NSNumber class]]) {
      NSNumber *theNumber = (NSNumber*)theObject;
      double theDouble = [theNumber doubleValue];
      //      if (bMinFound == false) {
      //        self.corePlotMinValue = theDouble;
      //        bMinFound = true;
      //      }
      if (bMaxFound == false) {
        self.corePlotMaxValue = theDouble;
        bMaxFound = true;
      }
      
      //      if (theDouble < self.corePlotMinValue) {
      //        self.corePlotMinValue = theDouble;
      //        bMinFound = true;
      //      }
      if (theDouble > self.corePlotMaxValue) {
        self.corePlotMaxValue = theDouble;
        bMaxFound = true;
      }
    }
  }
  
  self.mpCorePlotDataPoints = theNewArray;
  self.mpCorePlotDates = theDateArray;
  
  NSString *debugString = [NSString stringWithFormat:@"%s:%d, self.mpCorePlotDataPoints.count=%d", __FUNCTION__, __LINE__, (int)self.mpCorePlotDataPoints.count];
  [SKCore sAppendLogString:debugString IsError:NO];
}

+(NSString*) sConvertJsonDataToString:(NSData*)jsonData {
  
  NSError* error;
  id obj =
  //self.mpLocalDateDictForTestType =
  [NSJSONSerialization
   JSONObjectWithData:jsonData
   options:kNilOptions
   error:&error];
  
  NSDictionary *jsonDataForCorePlot;
  
  if ([obj isKindOfClass:[NSArray class]]) {
    jsonDataForCorePlot = @{@"root": (NSArray*)obj};
  } else if ([obj isKindOfClass:[NSDictionary class]]) {
    jsonDataForCorePlot = [NSDictionary dictionaryWithDictionary:obj];
  } else {
    SK_ASSERT(false);
    return nil;
  }
  
  // http://stackoverflow.com/questions/2467844/convert-utf-8-encoded-nsdata-to-nsstring
  NSData *serializedData = [NSJSONSerialization dataWithJSONObject:jsonDataForCorePlot
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
  // The data is not nul-terminated!
  //NSString *jsonString = [NSString stringWithUTF8String:(const char*)[jsonData bytes]];
  NSString *jsonString = [[NSString alloc] initWithData:serializedData encoding:NSUTF8StringEncoding];
  return jsonString;
}

-(void)updateGraphWithTheseResults:(NSData*)jsonData OnParentView:(UIView*)inParentView InFrame:(CGRect)inFrame StartHidden:(BOOL)inStartHidden WithDateFilter:(DATERANGE_1w1m3m1y)inDateFilter
{
  self.mDateFilter = inDateFilter;
  
  NSError* error = nil;
  id obj = [NSJSONSerialization
            JSONObjectWithData:jsonData
            options:kNilOptions
            error:&error];
  
  if (error != nil) {
    NSString *debugString = [NSString stringWithFormat:@"ERROR: %s:%d : error (%d : %@)", __FUNCTION__, __LINE__, (int)error.code, [error localizedDescription]];
    [SKCore sAppendLogString:debugString IsError:YES];
    return;
  }
  
  self.mpLocalDateDictForTestType = obj;
  
#ifdef DEBUG
  NSString *jsonString = [self.class sConvertJsonDataToString:jsonData];
  NSLog(@"DEBUG: Json data in %s=%@", __FUNCTION__, jsonString);
#endif // DEBUG
 
  /*
  // DEBUG SPEFICIC TEST CASES!
  NSString *testJsonString = @"{"
"  \"results\" : {"
"    \"downstream_mt\" : {"
"      \"2013-10-31\" : \"11.42\","
"      \"2013-10-30\" : \"11.43\","
"      \"2013-10-29\" : \"11.45\","
"      \"2013-11-01\" : \"11.45\","
"      \"2013-10-28\" : \"11.41\","
"      \"2013-10-27\" : \"11.45\","
"      \"2013-10-26\" : \"11.40\","
"      \"2013-10-25\" : \"11.43\""
"    }"
"  },"
"  \"request\" : {"
"    \"unit_id\" : \"237524\","
"    \"start_date\" : \"2013-10-25\","
"    \"tests\" : ["
"               \"downstream_mt\""
"               ],"
"    \"end_date\" : \"2013-11-01\""
"  }"
"}";
  NSData *data = [testJsonString dataUsingEncoding:NSUTF8StringEncoding];
  error = nil;
  self.mpLocalDateDictForTestType = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  */
  
  [self extractCorePlotData];
  
  if (self.mpHostView != nil) {
    if (self.mpCorePlot != nil) {
      [self.mpGraph removePlot:self.mpCorePlot];
      self.mpCorePlot = nil;
      self.mpGraph = nil;
    }
    [self.mpHostView removeFromSuperview];
    self.mpHostView = nil;
  }
  
  SK_ASSERT([NSThread isMainThread]);
  
  // Create the host view
  self.mpHostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:inFrame];
  self.mpHostView.allowPinchScaling = NO;
  [inParentView addSubview:self.mpHostView];
  self.mpHostView.hidden = inStartHidden;
  
  //CPTTheme *selectedTheme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
  CPTTheme *selectedTheme = nil;
  self.mpCorePlot = [self renderInLayer:self.mpHostView withTheme:selectedTheme animated:NO WithDateFilter:inDateFilter];
}

#pragma mark CTPlotDataSource (begin)

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
  
  NSString *debugString = [NSString stringWithFormat:@"%s:%d, numberOfRecordsForPlot=%d", __FUNCTION__, __LINE__, (int) self.mpCorePlotDataPoints.count];
  [SKCore sAppendLogString:debugString IsError:NO];
  
  return self.mpCorePlotDataPoints.count;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx {
  switch (fieldEnum)
  {
    case CPTScatterPlotFieldX:
    {
      NSString *debugString = [NSString stringWithFormat:@"%s:%d, CPTScatterPlotFieldX, idx=%d", __FUNCTION__, __LINE__, (int)idx];
      [SKCore sAppendLogString:debugString IsError:NO];
      
      // We're using a CPTTimeFormatter.
      // So, return INTERVAL since the system reference date.
      
      if (self.mpCorePlotDates.count <= 1) {
        debugString = [NSString stringWithFormat:@"%s:%d, no core plot dates", __FUNCTION__, __LINE__];
        [SKCore sAppendLogString:debugString IsError:YES];
        
        SK_ASSERT(false);
        return [NSNumber numberWithInt:0];
      }
      
      NSDate *theDate = self.mpCorePlotDates[idx];
      if (self.mDateFilter == DATERANGE_1w1m3m1y_ONE_DAY) {
        //double timeInterval = [theDate timeIntervalSinceDate:[NSDate date]
        NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:-oneDay];
        double timeInterval = [theDate timeIntervalSinceDate:yesterday];
        return [NSDecimalNumber numberWithDouble:timeInterval];
      }

      double timeInterval = [theDate timeIntervalSinceDate:self.mpCorePlotDates[0]];
      return [NSDecimalNumber numberWithDouble:timeInterval];
    }
      
    case CPTScatterPlotFieldY:
    {
      NSString *debugString = [NSString stringWithFormat:@"%s:%d, CPTScatterPlotFieldY, idx=%d", __FUNCTION__, __LINE__, (int)idx];
      [SKCore sAppendLogString:debugString IsError:NO];
      
      if (idx > self.mpCorePlotDataPoints.count) {
        NSString *debugString = [NSString stringWithFormat:@"%s:%d, idx too big", __FUNCTION__, __LINE__];
        [SKCore sAppendLogString:debugString IsError:YES];
        
        SK_ASSERT(false);
        return [NSNumber numberWithInt:0];
      }
      
      NSObject *theObject = self.mpCorePlotDataPoints[idx];
      if (theObject == nil) {
        NSString *debugString = [NSString stringWithFormat:@"%s:%d, theObject is nil", __FUNCTION__, __LINE__];
        [SKCore sAppendLogString:debugString IsError:YES];
        
        SK_ASSERT(false);
        return [NSNumber numberWithInt:0];
      }
      
      if ([theObject isKindOfClass:[NSString class]] == true) {
        NSString *theValue = (NSString *)theObject;
        theObject = @([theValue doubleValue]);
      }
      
      if ([theObject isKindOfClass:[NSNumber class]] == false) {
        // Placeholder!
        return [NSNumber numberWithInt:0];
      }
      
      NSNumber *theNumber = (NSNumber*)theObject;
      
      double range = self.corePlotMaxValue - self.corePlotMinValue;
      if (range == 0.0) {
        //SK_ASSERT(false);
        return [NSNumber numberWithInt:0];
      }
      double theValue = [theNumber doubleValue];
      
      // 100.0 is our nominal Y scale
      double scaledValueToUi = theValue; // 90.0 * ((theValue - self.corePlotMinValue)/ range);
      
      debugString = [NSString stringWithFormat:@"%s:%d, scaledValue=%g", __FUNCTION__, __LINE__, scaledValueToUi];
      [SKCore sAppendLogString:debugString IsError:NO];
      
      return [NSNumber numberWithDouble:scaledValueToUi];
    }
  }
  return nil;
}

#pragma mark CTPlotDataSource (end)

#pragma mark CPTAxisDelegate

// If we're using the 24-hour view, we use this delegate to use custom labels;
// this is because there are simply too many labels for a 24 hours of data!

// http://stackoverflow.com/questions/9054979/core-plot-how-to-change-color-of-negative-axis-tick-labels
-(BOOL)axis:(CPTAxis *)axis shouldUpdateAxisLabelsAtLocations:(NSSet *)locations {
  
  NSNumberFormatter *formatter = (NSNumberFormatter*)axis.labelFormatter;
  CGFloat labelOffset          = axis.labelOffset;
  //NSDecimalNumber *zero        = [NSDecimalNumber zero];
  
  // NSMutableSet is never sorted!
  // But, we need to analyse in time order!
  // http://stackoverflow.com/questions/9686555/sorting-nsmutableset
  NSArray *unsortedArrayOfTickLocations = [locations allObjects];
  NSArray* sortedArrayOfTickLocations = [unsortedArrayOfTickLocations sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    return [((NSDecimalNumber*) obj1) doubleValue] < [((NSDecimalNumber*) obj2) doubleValue];
  }];
  
  NSMutableSet *newLabels = [NSMutableSet set];
 
  int i = 0;
  for ( NSDecimalNumber *tickLocation in sortedArrayOfTickLocations ) {
    CPTTextStyle *theLabelTextStyle;
    
    CPTMutableTextStyle *newStyle = [axis.labelTextStyle mutableCopy];
    if ( (i % 4) == 0)
    {
      NSLog (@"SHOW %d" ,i);
      newStyle.color = [CPTColor blackColor];
    } else {
      NSLog (@"HIDE %d" ,i);
      newStyle.color = [CPTColor clearColor];
    }
    
    theLabelTextStyle = newStyle;
//    else {
//      // Hide it!
//      CPTMutableTextStyle *newStyle = [axis.labelTextStyle mutableCopy];
//      newStyle.color = [CPTColor clearColor];
//      theLabelTextStyle = newStyle;
//    }
  
    NSString *labelString       = [formatter stringForObjectValue:tickLocation];
    CPTTextLayer *newLabelLayer = [[CPTTextLayer alloc] initWithText:labelString style:theLabelTextStyle];
    
    CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithContentLayer:newLabelLayer];
    newLabel.tickLocation = tickLocation.decimalValue;
    newLabel.offset       = labelOffset;
    
    [newLabels addObject:newLabel];
    
    i++;
  }
  
  axis.axisLabels = newLabels;

  
  return NO;
}

@end
