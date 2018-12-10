//+------------------------------------------------------------------+
//|                                                  VolumeBands.mq5 |
//| Copyright https://linkedin.com/in/carlos-andré-oliveira-01337023 |
//|                                  http://github.com/candreoliveira|
//+------------------------------------------------------------------+

#property copyright "https://linkedin.com/in/carlos-andré-oliveira-01337023"
#property link "http://github.com/candreoliveira"
#property description "Volume Bands"
#property version "1.00"

#include <Custom/Bands.mqh>

#property indicator_chart_window
#property script_show_inputs
#property indicator_applied_price PRICE_CLOSE

#property indicator_buffers 6
#property indicator_plots 5

#property indicator_type1 DRAW_LINE
#property indicator_color1 clrMediumBlue
#property indicator_label1 "Bands upper"
#property indicator_style1 2

#property indicator_type2 DRAW_LINE
#property indicator_color2 clrDodgerBlue
#property indicator_label2 "Bands middle upper"
#property indicator_style2 2

#property indicator_type3 DRAW_LINE
#property indicator_color3 clrLightSkyBlue
#property indicator_label3 "Bands middle"
#property indicator_style3 3

#property indicator_type4 DRAW_LINE
#property indicator_color4 clrDodgerBlue
#property indicator_label4 "Bands middle lower"
#property indicator_style4 2

#property indicator_type5 DRAW_LINE
#property indicator_color5 clrMediumBlue
#property indicator_label5 "Bands lower"
#property indicator_style5 2

//--- input parametrs
input ENUM_APPLIED_VOLUME VolumeType = VOLUME_REAL; // Volume Type

input int InpBandsPeriod = 21; // Period
input int InpBandsShift = 0; // Shift
input double InpBandsDeviations = 2.0; // Deviation

input int firstLimit = 1; // 1st Index Limit (Wgt Avg)
input double firstWeight = 10; // 1st Weight (Wgt Avg)

input int secondLimit = 7; // 2nd Index Limit (Wgt Avg)
input double secondWeight = 5; // 2nd Weight (Wgt Avg)

input int thirdLimit = 14; // 3rd Index Limit (Wgt Avg)
input double thirdWeight = 3; // 3rd Weight (Wgt Avg)

input int fourthLimit = 21; // 4th Index Limit (Wgt Avg)
input double fourthWeight = 1; // 4th Weight (Wgt Avg)

input double defaultWeight = 0.5; // Default Weight (Wgt Avg)

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
    if (VolumeType == VOLUME_REAL) {
      ChartSetInteger(cid, CHART_SHOW_VOLUMES, CHART_VOLUME_REAL);
    } else {
      ChartSetInteger(cid, CHART_SHOW_VOLUMES, CHART_VOLUME_TICK);
    }

    ChartSetInteger(cid, CHART_SHOW_GRID, 1);
    ChartSetInteger(cid, CHART_COLOR_VOLUME, clrBlue);
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
  IndicatorSetString(INDICATOR_SHORTNAME, "Volume Bands");

  //--- indexes draw begin settings
  ExtPlotBegin = ExtBandsPeriod - 1;
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, ExtBandsPeriod);
  PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, ExtBandsPeriod);
  PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, ExtBandsPeriod);
  PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, ExtBandsPeriod);
  PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, ExtBandsPeriod);

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
    if (VolumeType==VOLUME_TICK) {
      //--- middle line
      ExtMLBuffer[i] = Bands_ProgressionWeightedMA(
        i,
        close,
        tick_volume,
        ExtBandsPeriod,
        firstLimit, firstWeight,
        secondLimit, secondWeight,
        thirdLimit, thirdWeight,
        fourthLimit, fourthWeight,
        defaultWeight);
    } else {
      ExtMLBuffer[i] = Bands_ProgressionWeightedMA(
        i,
        close,
        volume,
        ExtBandsPeriod,
        firstLimit, firstWeight,
        secondLimit, secondWeight,
        thirdLimit, thirdWeight,
        fourthLimit, fourthWeight,
        defaultWeight);
    }

    //--- calculate and write down StdDev
    ExtStdDevLBuffer[i] = Bands_StdDev(i, close, ExtMLBuffer[i], ExtBandsPeriod);
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