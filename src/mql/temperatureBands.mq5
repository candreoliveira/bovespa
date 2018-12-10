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

#property indicator_buffers 8
#property indicator_plots 6

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

//--- input parametrs
input ENUM_APPLIED_VOLUME volumeType = VOLUME_REAL; // Volume

input int bandsPeriod = 21; // Period
input int bandsShift = 0; // Shift
input double bandsDeviations = 2.0; // Deviation

input int firstLimit = 1; // 1st Index Limit (Wgt Avg)
input double firstWeight = 10; // 1st Weight (Wgt Avg)

input int secondLimit = 7; // 2nd Index Limit (Wgt Avg)
input double secondWeight = 5; // 2nd Weight (Wgt Avg)

input int thirdLimit = 14; // 3rd Index Limit (Wgt Avg)
input double thirdWeight = 3; // 3rd Weight (Wgt Avg)

input int fourthLimit = 21; // 4th Index Limit (Wgt Avg)
input double fourthWeight = 1; // 4th Weight (Wgt Avg)

input double defWeight = 0.5; // Default Weight (Wgt Avg)

input int stochPeriodK = 21; // Stochastic Period K
input int stochPeriodD = 7; // Stochastic Period D
input int stochSlowing = 3; // Stochastic Slowing
input ENUM_MA_METHOD stochMAType = MODE_SMA; // Stochastic Moving Average Type
input ENUM_STO_PRICE stochPrice = STO_CLOSECLOSE; // Stochastic Price

input int stochUpperLevel = 60; // Stochastic Upper Level
input int stochLowerLevel = 35; // Stochastic Lower Level

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
double trend[];
double mark[];

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
  SetIndexBuffer(6, trend, INDICATOR_CALCULATIONS);
  SetIndexBuffer(7, mark, INDICATOR_CALCULATIONS);

  //--- set index labels
  PlotIndexSetString(0, PLOT_LABEL, "Hot Bands Up(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(1, PLOT_LABEL, "Warm Bands Up(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(2, PLOT_LABEL, "Cold Bands Up(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(3, PLOT_LABEL, "Hot Bands Down(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(4, PLOT_LABEL, "Warm Bands Down(" + string(extBandsPeriod) + ")");
  PlotIndexSetString(5, PLOT_LABEL, "Cold Bands Down(" + string(extBandsPeriod) + ")");

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

  //--- indexes shift settings
  PlotIndexSetInteger(0, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(1, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(2, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(3, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(4, PLOT_SHIFT, extBandsShift);
  PlotIndexSetInteger(5, PLOT_SHIFT, extBandsShift);

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

  PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, 0.0);

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
  ArrayInitialize(trend, -1.0);
  ArrayInitialize(mark, -1.0);
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

  double _stoK[], _stoD[],
         _pBandUpper[], _pBandMidUpper[], _pBandLower[], _pBandMidLower[], _pBandMid[],
         _vBandUpper[], _vBandMidUpper[], _vBandLower[], _vBandMidLower[], _vBandMid[];
  double tempHot, tempWarm, tempCold;
  int tempTrend = -1, tempMark = -1, maxCopied = 0, tmpMaxCopied = 0;

  maxCopied = CopyBuffer(stoch, MAIN_LINE, 0, rates_total, _stoK);
  if (maxCopied <= extBandsPeriod) { return(0); }

  tmpMaxCopied = CopyBuffer(stoch, SIGNAL_LINE, 0, rates_total, _stoD);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(priceBands, 0, 0, rates_total, _pBandUpper);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(priceBands, 1, 0, rates_total, _pBandMidUpper);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(priceBands, 2, 0, rates_total, _pBandMid);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(priceBands, 3, 0, rates_total, _pBandMidLower);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(priceBands, 4, 0, rates_total, _pBandLower);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(volumeBands, 0, 0, rates_total, _vBandUpper);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(volumeBands, 1, 0, rates_total, _vBandMidUpper);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(volumeBands, 2, 0, rates_total, _vBandMid);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(volumeBands, 3, 0, rates_total, _vBandMidLower);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  tmpMaxCopied = CopyBuffer(volumeBands, 4, 0, rates_total, _vBandLower);
  if (tmpMaxCopied <= extBandsPeriod) { return(0); }
  if (tmpMaxCopied < maxCopied) { maxCopied = tmpMaxCopied; }

  //--- main cycle
  for(int i = pos; i < maxCopied && !IsStopped(); i++) {
    Bands_Temperature(_stoK, _stoD, trend, stochUpperLevel, stochLowerLevel,
                      _pBandUpper, _pBandMidUpper, _pBandLower, _pBandMidLower, _pBandMid,
                      _vBandUpper, _vBandMidUpper, _vBandLower, _vBandMidLower, _vBandMid,
                      close, i, extBandsPeriod, tempHot, tempWarm, tempCold, tempTrend, tempMark);

    if (tempHot >= 0.0) {
      if (tempMark == 0 || tempMark == 1 || tempMark == 2) hotUp[i] = tempHot;
      else if (tempMark == 6 || tempMark == 5 || tempMark == 4) hotDown[i] = tempHot;
    }

    if (tempWarm >= 0.0) {
      if (tempMark == 0 || tempMark == 1 || tempMark == 2) warmUp[i] = tempWarm;
      else if (tempMark == 6 || tempMark == 5 || tempMark == 4) warmDown[i] = tempWarm;
    }

    if (tempCold >= 0.0) {
      if (tempMark == 0 || tempMark == 1 || tempMark == 2) coldUp[i] = tempCold;
      else if (tempMark == 6 || tempMark == 5 || tempMark == 4) coldDown[i] = tempCold;
    }

    trend[i] = (double)tempTrend;
    mark[i] = (double)tempMark;
  }

  return(maxCopied);
}