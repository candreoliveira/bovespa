//+------------------------------------------------------------------+
//|                                             TemperatureBands.mq5 |
//| Copyright https://linkedin.com/in/carlos-andré-oliveira-01337023 |
//|                                  http://github.com/candreoliveira|
//+------------------------------------------------------------------+

#property copyright "https://linkedin.com/in/carlos-andré-oliveira-01337023"
#property link "http://github.com/candreoliveira"
#property description "Temperature Bands"

#include <Custom/Bands.mqh>

#property indicator_chart_window
#property script_show_inputs
#property indicator_applied_price PRICE_CLOSE

#property indicator_buffers 17
#property indicator_plots 16

#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrChocolate
#property indicator_label1 "Hot Change Up"
#property indicator_style1 3

#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrGold
#property indicator_label2 "Warm Change Up"
#property indicator_style2 3

#property indicator_type3 DRAW_ARROW
#property indicator_color3 clrBlueViolet
#property indicator_label3 "Cold Change Up"
#property indicator_style3 3

#property indicator_type4 DRAW_ARROW
#property indicator_color4 clrChocolate
#property indicator_label4 "Hot Change Down"
#property indicator_style4 3

#property indicator_type5 DRAW_ARROW
#property indicator_color5 clrGold
#property indicator_label5 "Warm Change Down"
#property indicator_style5 3

#property indicator_type6 DRAW_ARROW
#property indicator_color6 clrBlueViolet
#property indicator_label6 "Cold Change Down"
#property indicator_style6 3

#property indicator_type7 DRAW_LINE
#property indicator_color7 clrLightSkyBlue
#property indicator_label7 "Price Weighted (CV) Band Upper"
#property indicator_style7 2

#property indicator_type8 DRAW_LINE
#property indicator_color8 clrDodgerBlue
#property indicator_label8 "Price Weighted (CV) Band Middle Upper"
#property indicator_style8 4

#property indicator_type9 DRAW_LINE
#property indicator_color9 clrMediumBlue
#property indicator_label9 "Price Weighted (CV) Band Middle"
#property indicator_style9 3

#property indicator_type10 DRAW_LINE
#property indicator_color10 clrDodgerBlue
#property indicator_label10 "Price Weighted (CV) Band Middle Lower"
#property indicator_style10 4

#property indicator_type11 DRAW_LINE
#property indicator_color11 clrLightSkyBlue
#property indicator_label11 "Price Weighted (CV) Band Lower"
#property indicator_style11 2

#property indicator_type12 DRAW_LINE
#property indicator_color12 clrDarkSeaGreen
#property indicator_label12 "Price Weighted (HLCC) Band Upper"
#property indicator_style12 2

#property indicator_type13 DRAW_LINE
#property indicator_color13 clrMediumSeaGreen
#property indicator_label13 "Price Weighted (HLCC) Band Middle Upper"
#property indicator_style13 4

#property indicator_type14 DRAW_LINE
#property indicator_color14 clrSeaGreen
#property indicator_label14 "Price Weighted (HLCC) Band Middle"
#property indicator_style14 3

#property indicator_type15 DRAW_LINE
#property indicator_color15 clrMediumSeaGreen
#property indicator_label15 "Price Weighted (HLCC) Band Middle Lower"
#property indicator_style15 4

#property indicator_type16 DRAW_LINE
#property indicator_color16 clrDarkSeaGreen
#property indicator_label16 "Price Weighted (HLCC) Band Lower"
#property indicator_style16 2

//--- input parametrs
input ENUM_APPLIED_VOLUME volumeType = VOLUME_REAL; // Volume

input int bandsPeriod = 21; // Period
input int bandsShift = 0; // Shift
input double bandsDeviations = 2.0; // Deviation

input int firstLimit = 1; // 1st Index Limit (CV Weighted Avg)
input double firstWeight = 10; // 1st Weight (CV Weighted Avg)

input int secondLimit = 7; // 2nd Index Limit (CV Weighted Avg)
input double secondWeight = 5; // 2nd Weight (CV Weighted Avg)

input int thirdLimit = 14; // 3rd Index Limit (CV Weighted Avg)
input double thirdWeight = 3; // 3rd Weight (CV Weighted Avg)

input int fourthLimit = 21; // 4th Index Limit (CV Weighted Avg)
input double fourthWeight = 1; // 4th Weight (CV Weighted Avg)

input double defWeight = 0.5; // Default Weight (CV Weighted Avg)

input int stochPeriodK = 21; // Period K (Stochastic)
input int stochPeriodD = 7; // Period D (Stochastic)
input int stochSlowing = 3; // Slowing (Stochastic)
input ENUM_MA_METHOD stochMAType = MODE_SMA; // Moving Average Type (Stochastic)
input ENUM_STO_PRICE stochPrice = STO_CLOSECLOSE; // Price Type (Stochastic)

input int stochUpperLevel = 60; // Upper Thresold (Stochastic)
input int stochLowerLevel = 35; // Lower Thresold (Stochastic)

//--- global variables
int extBandsPeriod,
    extBandsShift,
    extPlotBegin = 0,
    stoch = 0,
    priceBands = 0,
    volumeBands = 0;
double extBandsDeviations;
ENUM_CHART_VOLUME_MODE chartVolumeType;

//---- indicator buffer
double hotUp[];
double warmUp[];
double coldUp[];
double hotDown[];
double warmDown[];
double coldDown[];
double cvUpper[];
double cvMiddleUpper[];
double cvMiddle[];
double cvMiddleLower[];
double cvLower[];
double hlccUpper[];
double hlccMiddleUpper[];
double hlccMiddle[];
double hlccMiddleLower[];
double hlccLower[];
double trend[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit() {
  const long cid = ChartID();

  if (cid > 0) {
    if (volumeType == VOLUME_REAL) {
      chartVolumeType = CHART_VOLUME_REAL;
    } else {
      chartVolumeType = CHART_VOLUME_TICK;
    }

    ChartSetInteger(cid, CHART_SHOW_VOLUMES, chartVolumeType);
    ChartSetInteger(cid, CHART_SHOW_GRID, 1);
    ChartSetInteger(cid, CHART_COLOR_VOLUME, clrBlue);
    ChartSetInteger(cid, CHART_COLOR_BACKGROUND, clrBlack);
  }

  //--- check for input values
  if(bandsPeriod < 2) {
    extBandsPeriod = 21;
    printf("Incorrect value for input variable bandsPeriod=%d. Indicator will use value=%d for calculations.", bandsPeriod, extBandsPeriod);
  } else {
    extBandsPeriod = bandsPeriod;
  }

  if(bandsShift < 0) {
    extBandsShift = 0;
    printf("Incorrect value for input variable bandsShift=%d. Indicator will use value=%d for calculations.", bandsShift, extBandsShift);
  } else {
    extBandsShift = bandsShift;
  }

  if(bandsDeviations == 0.0) {
    extBandsDeviations = 2.0;
    printf("Incorrect value for input variable bandsDeviations=%f. Indicator will use value=%f for calculations.", bandsDeviations, extBandsDeviations);
  } else {
    extBandsDeviations = bandsDeviations;
  }

  //--- define buffers
  SetIndexBuffer(0, hotUp, INDICATOR_DATA);
  SetIndexBuffer(1, warmUp, INDICATOR_DATA);
  SetIndexBuffer(2, coldUp, INDICATOR_DATA);
  SetIndexBuffer(3, hotDown, INDICATOR_DATA);
  SetIndexBuffer(4, warmDown, INDICATOR_DATA);
  SetIndexBuffer(5, coldDown, INDICATOR_DATA);
  SetIndexBuffer(6, cvUpper, INDICATOR_DATA);
  SetIndexBuffer(7, cvMiddleUpper, INDICATOR_DATA);
  SetIndexBuffer(8, cvMiddle, INDICATOR_DATA);
  SetIndexBuffer(9, cvMiddleLower, INDICATOR_DATA);
  SetIndexBuffer(10, cvLower, INDICATOR_DATA);
  SetIndexBuffer(11, hlccUpper, INDICATOR_DATA);
  SetIndexBuffer(12, hlccMiddleUpper, INDICATOR_DATA);
  SetIndexBuffer(13, hlccMiddle, INDICATOR_DATA);
  SetIndexBuffer(14, hlccMiddleLower, INDICATOR_DATA);
  SetIndexBuffer(15, hlccLower, INDICATOR_DATA);
  SetIndexBuffer(16, trend, INDICATOR_CALCULATIONS);

  //--- set index labels
  PlotIndexSetString(0, PLOT_LABEL, "Hot Bands Up(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(1, PLOT_LABEL, "Warm Bands Up(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(2, PLOT_LABEL, "Cold Bands Up(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(3, PLOT_LABEL, "Hot Bands Down(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(4, PLOT_LABEL, "Warm Bands Down(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(5, PLOT_LABEL, "Cold Bands Down(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(6, PLOT_LABEL, "Price Weighted (CV) Band Upper(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(7, PLOT_LABEL, "Price Weighted (CV) Band Middle Upper(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(8, PLOT_LABEL, "Price Weighted (CV) Band Middle(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(9, PLOT_LABEL, "Price Weighted (CV) Band Middle Lower(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(10, PLOT_LABEL, "Price Weighted (CV) Band Lower(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(11, PLOT_LABEL, "Price Weighted (HLCC) Band Upper(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(12, PLOT_LABEL, "Price Weighted (HLCC) Band Middle Upper(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(13, PLOT_LABEL, "Price Weighted (HLCC) Band Middle(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(14, PLOT_LABEL, "Price Weighted (HLCC) Band Middle Lower(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(15, PLOT_LABEL, "Price Weighted (HLCC) Band Lower(" + string(extBandsPeriod) + ")");

  //--- indicator name
  IndicatorSetString(INDICATOR_SHORTNAME, "Temperature Bands");

  //--- indexes draw begin settings
  extPlotBegin = extBandsPeriod - 1;
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(5, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(6, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(7, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(8, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(9, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(10, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(11, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(12, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(13, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(14, PLOT_DRAW_BEGIN, extBandsPeriod);
  PlotIndexSetInteger(15, PLOT_DRAW_BEGIN, extBandsPeriod);

  //--- indexes shift settings
  PlotIndexSetInteger(0, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(1, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(2, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(3, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(4, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(5, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(6, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(7, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(8, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(9, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(10, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(11, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(12, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(13, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(14, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(15, PLOT_SHIFT, extBandsShift);

  PlotIndexSetInteger(0, PLOT_ARROW, 217);
  PlotIndexSetInteger(1, PLOT_ARROW, 217);
  PlotIndexSetInteger(2, PLOT_ARROW, 217);
  PlotIndexSetInteger(3, PLOT_ARROW, 218);
  PlotIndexSetInteger(4, PLOT_ARROW, 218);
  PlotIndexSetInteger(5, PLOT_ARROW, 218);

  PlotIndexSetInteger(0, PLOT_ARROW_SHIFT, -12);
  PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, -12);
  PlotIndexSetInteger(2, PLOT_ARROW_SHIFT, -12);
  PlotIndexSetInteger(3, PLOT_ARROW_SHIFT, 12);
  PlotIndexSetInteger(4, PLOT_ARROW_SHIFT, 12);
  PlotIndexSetInteger(5, PLOT_ARROW_SHIFT, 12);

  PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrChocolate);
  PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrGold);
  PlotIndexSetInteger(2, PLOT_LINE_COLOR, clrBlueViolet);
  PlotIndexSetInteger(3, PLOT_LINE_COLOR, clrChocolate);
  PlotIndexSetInteger(4, PLOT_LINE_COLOR, clrGold);
  PlotIndexSetInteger(5, PLOT_LINE_COLOR, clrBlueViolet);
  PlotIndexSetInteger(6, PLOT_LINE_COLOR, clrLightSkyBlue);
  PlotIndexSetInteger(7, PLOT_LINE_COLOR, clrDodgerBlue);
  PlotIndexSetInteger(8, PLOT_LINE_COLOR, clrMediumBlue);
  PlotIndexSetInteger(9, PLOT_LINE_COLOR, clrDodgerBlue);
  PlotIndexSetInteger(10, PLOT_LINE_COLOR, clrLightSkyBlue);
  PlotIndexSetInteger(11, PLOT_LINE_COLOR, clrDarkSeaGreen);
  PlotIndexSetInteger(12, PLOT_LINE_COLOR, clrMediumSeaGreen);
  PlotIndexSetInteger(13, PLOT_LINE_COLOR, clrSeaGreen);
  PlotIndexSetInteger(14, PLOT_LINE_COLOR, clrMediumSeaGreen);
  PlotIndexSetInteger(15, PLOT_LINE_COLOR, clrDarkSeaGreen);

  PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(6, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(7, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(8, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(9, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(10, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(11, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(12, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(13, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(14, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(15, PLOT_EMPTY_VALUE, 0.0);

  //--- number of digits of indicator value
  IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);

  // Load Price Bands
  stoch = iStochastic(Symbol(),
                      0,
                      stochPeriodK,
                      stochPeriodD,
                      stochSlowing,
                      stochMAType,
                      stochPrice);

  // Load Price Bands
  priceBands = iCustom(Symbol(),
                        0, // current timeframe
                        "Custom\\PriceBands",
                        bandsPeriod, // Period
                        bandsShift,
                        bandsDeviations,
                        PRICE_WEIGHTED);

  // Load Volume Bands
  volumeBands = iCustom(Symbol(),
                        0, // current timeframe
                        "Custom\\VolumeBands",
                        volumeType,
                        bandsPeriod,
                        bandsShift,
                        bandsDeviations,
                        firstLimit,
                        firstWeight,
                        secondLimit,
                        secondWeight,
                        thirdLimit,
                        thirdWeight,
                        fourthLimit,
                        fourthWeight,
                        defWeight,
                        PRICE_CLOSE);

  ArrayInitialize(hotUp, 0.0);
  ArrayInitialize(warmUp, 0.0);
  ArrayInitialize(coldUp, 0.0);
  ArrayInitialize(hotDown, 0.0);
  ArrayInitialize(warmDown, 0.0);
  ArrayInitialize(coldDown, 0.0);
  ArrayInitialize(hlccLower, 0.0);
  ArrayInitialize(hlccMiddleLower, 0.0);
  ArrayInitialize(hlccMiddle, 0.0);
  ArrayInitialize(hlccMiddleUpper, 0.0);
  ArrayInitialize(hlccUpper, 0.0);
  ArrayInitialize(cvLower, 0.0);
  ArrayInitialize(cvMiddleLower, 0.0);
  ArrayInitialize(cvMiddle, 0.0);
  ArrayInitialize(cvMiddleUpper, 0.0);
  ArrayInitialize(cvUpper, 0.0);
  ArrayInitialize(trend, -1.0);
}

void onDeinit(const int reason) {
  IndicatorRelease(stoch);
  IndicatorRelease(volumeBands);
  IndicatorRelease(priceBands);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
  //--- variables
  int pos;

  if(rates_total < extPlotBegin) {
    return(0);
  }

  //--- starting calculation
  if(prev_calculated > 1) {
    pos = prev_calculated - 1;
  } else {
    pos = 0;
  }

  double _stoK[], _stoD[];
  double tempHotUp = 0.0, tempWarmUp = 0.0, tempColdUp = 0.0, tempHotDown = 0.0, tempWarmDown = 0.0, tempColdDown = 0.0;
  int tempTrend = -1, tempMark = -1, maxCopied = 0, tmpMaxCopied = 0;

  maxCopied = CopyBuffer(stoch, MAIN_LINE, 0, rates_total, _stoK);
  if (maxCopied <= extBandsPeriod) { return(0); }

  tmpMaxCopied = CopyBuffer(stoch, SIGNAL_LINE, 0, rates_total, _stoD);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(priceBands, 0, 0, rates_total, hlccUpper);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(priceBands, 1, 0, rates_total, hlccMiddleUpper);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(priceBands, 2, 0, rates_total, hlccMiddle);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(priceBands, 3, 0, rates_total, hlccMiddleLower);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(priceBands, 4, 0, rates_total, hlccLower);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(volumeBands, 0, 0, rates_total, cvUpper);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(volumeBands, 1, 0, rates_total, cvMiddleUpper);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(volumeBands, 2, 0, rates_total, cvMiddle);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(volumeBands, 3, 0, rates_total, cvMiddleLower);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(volumeBands, 4, 0, rates_total, cvLower);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  // Resizing arrays
  ArrayResize(trend, maxCopied, maxCopied);
  ArrayInitialize(trend, -1.0);

  //--- main cycle
  for(int i = pos; i < maxCopied && !IsStopped(); i++) {
    // Temperature calculations
    Bands_Temperature(_stoK, _stoD, trend, stochUpperLevel, stochLowerLevel,
                      hlccUpper, hlccMiddleUpper, hlccLower, hlccMiddleLower, hlccMiddle,
                      cvUpper, cvMiddleUpper, cvLower, cvMiddleLower, cvMiddle,
                      hotUp, hotDown, warmUp, warmDown, coldUp, coldDown,
                      close, i, extBandsPeriod,
                      tempTrend, tempHotUp, tempWarmUp, tempColdUp, tempHotDown, tempWarmDown, tempColdDown);

    hotUp[i] = tempHotUp;
    hotDown[i] = tempHotDown;
    warmUp[i] = tempWarmUp;
    warmDown[i] = tempWarmDown;
    coldUp[i] = tempColdUp;
    coldDown[i] = tempColdDown;
    trend[i] = (double)tempTrend;
  }

  return(maxCopied);
}