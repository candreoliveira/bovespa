//+------------------------------------------------------------------+
//|                                                   PriceBands.mq5 |
//| Copyright https://linkedin.com/in/carlos-andré-oliveira-01337023 |
//|                                  http://github.com/candreoliveira|
//+------------------------------------------------------------------+

#property copyright "https://linkedin.com/in/carlos-andré-oliveira-01337023"
#property link "http://github.com/candreoliveira"
#property description "Price Bands"
#property version "1.00"

#include <MovingAverages.mqh>
#include <Custom/Bands.mqh>

#property indicator_chart_window
#property script_show_inputs
#property indicator_applied_price PRICE_WEIGHTED

#property indicator_buffers 6
#property indicator_plots 5

#property indicator_type1 DRAW_LINE
#property indicator_color1 clrSeaGreen
#property indicator_label1 "Bands upper"
#property indicator_style1 2

#property indicator_type2 DRAW_LINE
#property indicator_color2 clrMediumSeaGreen
#property indicator_label2 "Bands middle upper"
#property indicator_style2 2

#property indicator_type3 DRAW_LINE
#property indicator_color3 clrDarkSeaGreen
#property indicator_label3 "Bands middle"
#property indicator_style3 3

#property indicator_type4 DRAW_LINE
#property indicator_color4 clrMediumSeaGreen
#property indicator_label4 "Bands middle lower"
#property indicator_style4 2

#property indicator_type5 DRAW_LINE
#property indicator_color5 clrSeaGreen
#property indicator_label5 "Bands lower"
#property indicator_style5 2

//--- input parametrs
input int InpBandsPeriod = 21; // Period
input int InpBandsShift = 0; // Shift
input double InpBandsDeviations = 2.0; // Deviation

//--- global variables
int ExtBandsPeriod, ExtBandsShift;
double ExtBandsDeviations;
int ExtPlotBegin = 0;

//---- indicator buffer
// middle line
double ExtMLBuffer[];
// middle upper line
double ExtMULBuffer[];
// middle lower line
double ExtMLLBuffer[];
// upper line
double ExtULBuffer[];
// lower line
double ExtLLBuffer[];
// std dev line
double ExtStdDevLBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit() {
  const long cid = ChartID();
  if (cid > 0) {
    ChartSetInteger(cid, CHART_SHOW_GRID, 1);
    ChartSetInteger(cid, CHART_COLOR_BACKGROUND, clrBlack);
  }

  //--- check for input values
  if(InpBandsPeriod < 2) {
    ExtBandsPeriod = 21;
    printf("Incorrect value for input variable InpBandsPeriod=%d. Indicator will use value=%d for calculations.", InpBandsPeriod, ExtBandsPeriod);
  } else {
    ExtBandsPeriod = InpBandsPeriod;
  }

  if(InpBandsShift < 0) {
    ExtBandsShift = 0;
    printf("Incorrect value for input variable InpBandsShift=%d. Indicator will use value=%d for calculations.", InpBandsShift, ExtBandsShift);
  } else {
    ExtBandsShift = InpBandsShift;
  }

  if(InpBandsDeviations == 0.0) {
    ExtBandsDeviations = 2.0;
    printf("Incorrect value for input variable InpBandsDeviations=%f. Indicator will use value=%f for calculations.", InpBandsDeviations, ExtBandsDeviations);
  } else {
    ExtBandsDeviations = InpBandsDeviations;
  }

  //--- define buffers
  SetIndexBuffer(0, ExtULBuffer);
  SetIndexBuffer(1, ExtMULBuffer);
  SetIndexBuffer(2, ExtMLBuffer);
  SetIndexBuffer(3, ExtMLLBuffer);
  SetIndexBuffer(4, ExtLLBuffer);
  SetIndexBuffer(5, ExtStdDevLBuffer, INDICATOR_CALCULATIONS);

  //--- set index labels
  PlotIndexSetString(0, PLOT_LABEL, "Bands(" + string(ExtBandsPeriod) + ") Upper");
  PlotIndexSetString(1, PLOT_LABEL, "Bands(" + string(ExtBandsPeriod) + ") Middle Upper");
  PlotIndexSetString(2, PLOT_LABEL, "Bands(" + string(ExtBandsPeriod) + ") Middle");
  PlotIndexSetString(3, PLOT_LABEL, "Bands(" + string(ExtBandsPeriod) + ") Middle Lower");
  PlotIndexSetString(4, PLOT_LABEL, "Bands(" + string(ExtBandsPeriod) + ") Lower");

  //--- indicator name
  IndicatorSetString(INDICATOR_SHORTNAME, "Price Bands");

  //--- indexes draw begin settings
  ExtPlotBegin = ExtBandsPeriod - 1;
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, ExtBandsPeriod);
  PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, ExtBandsPeriod);
  PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, ExtBandsPeriod);
  PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, ExtBandsPeriod);
  PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, ExtBandsPeriod);

  // PlotIndexSetInteger(0, PLOT_LINE_STYLE, STYLE_DOT);
  // PlotIndexSetInteger(1, PLOT_LINE_STYLE, STYLE_DOT);
  // PlotIndexSetInteger(2, PLOT_LINE_STYLE, STYLE_SOLID);
  // PlotIndexSetInteger(3, PLOT_LINE_STYLE, STYLE_DOT);
  // PlotIndexSetInteger(4, PLOT_LINE_STYLE, STYLE_DOT);

  //--- indexes shift settings
  PlotIndexSetInteger(0, PLOT_SHIFT, ExtBandsShift);
  PlotIndexSetInteger(1, PLOT_SHIFT, ExtBandsShift);
  PlotIndexSetInteger(2, PLOT_SHIFT, ExtBandsShift);
  PlotIndexSetInteger(3, PLOT_SHIFT, ExtBandsShift);
  PlotIndexSetInteger(4, PLOT_SHIFT, ExtBandsShift);

  //--- number of digits of indicator value
  IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);

  PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
  PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0.0);

  ArrayInitialize(ExtULBuffer, 0.0);
  ArrayInitialize(ExtMULBuffer, 0.0);
  ArrayInitialize(ExtMLBuffer, 0.0);
  ArrayInitialize(ExtMLLBuffer, 0.0);
  ArrayInitialize(ExtLLBuffer, 0.0);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
  //--- variables
  int pos;

  //--- indexes draw begin settings, when we've recieved previous begin
  if(ExtPlotBegin != ExtBandsPeriod + begin) {
    ExtPlotBegin = ExtBandsPeriod + begin;
    PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, ExtPlotBegin);
    PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, ExtPlotBegin);
    PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, ExtPlotBegin);
    PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, ExtPlotBegin);
    PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, ExtPlotBegin);
  }

  //--- check for bars count
  if(rates_total < ExtPlotBegin) {
    return(0);
  }

  //--- starting calculation
  if(prev_calculated > 1) {
    pos = prev_calculated - 1;
  } else {
    pos = 0;
  }

  //--- main cycle
  for(int i = pos; i < rates_total && !IsStopped(); i++) {
    //--- middle line
    ExtMLBuffer[i] = SimpleMA(i, ExtBandsPeriod, price);
    //--- calculate and write down StdDev
    ExtStdDevLBuffer[i] = Bands_StdDev(i, price, ExtMLBuffer[i], ExtBandsPeriod);
    //--- upper line
    ExtULBuffer[i] = ExtMLBuffer[i] + ExtBandsDeviations*ExtStdDevLBuffer[i];
    //--- lower line
    ExtLLBuffer[i] = ExtMLBuffer[i] - ExtBandsDeviations*ExtStdDevLBuffer[i];
    //--- middle upper line
    ExtMULBuffer[i] = ExtMLBuffer[i] + (ExtBandsDeviations/2)*ExtStdDevLBuffer[i];
    //--- middle lower line
    ExtMLLBuffer[i] = ExtMLBuffer[i] - (ExtBandsDeviations/2)*ExtStdDevLBuffer[i];
    //---
  }

  //---- OnCalculate done. Return new prev_calculated.
  return(rates_total);
}
//+------------------------------------------------------------------+
