//+------------------------------------------------------------------+
//|                                                        Bands.mqh |
//| Copyright https://linkedin.com/in/carlos-andré-oliveira-01337023 |
//|                                  http://github.com/candreoliveira|
//+------------------------------------------------------------------+

#property copyright "https://linkedin.com/in/carlos-andré-oliveira-01337023"
#property link "http://github.com/candreoliveira"
#property description "Bands Helper"

//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double Bands_StdDev(int position, const double &chg[], double base, int p) {
  //--- variables
  double StdDev_dTmp = 0.0;

  //--- check for position
  if(position < p) {
    return(StdDev_dTmp);
  }

  //--- calcualte StdDev
  for(int i=0; i < p; i++) {
    StdDev_dTmp += MathPow(chg[position-i] - base, 2);
  }

  StdDev_dTmp = MathSqrt(StdDev_dTmp / p);
  //--- return calculated value

  return(StdDev_dTmp);
}

//+------------------------------------------------------------------+
//| Calculate Weighted Average                                       |
//+------------------------------------------------------------------+
double Bands_WeightedMA(int position, const double &values[], const long &weight[], int p) {
  //--- variables
  double WeightedAvg_dTmp = 0.0;
  double WeightedAvg_tmp = 0.0;

  //--- check for position
  if(position < p) {
    return(WeightedAvg_tmp);
  }

  //--- calcualte WeightedAvg
  for(int i=0; i < p; i++) {
    double w = weight[position - i] || 1;
    WeightedAvg_dTmp += w;
    WeightedAvg_tmp += values[position - i] * w;
  }

  if (WeightedAvg_dTmp > 0) {
    WeightedAvg_tmp = WeightedAvg_tmp / WeightedAvg_dTmp;
    return(WeightedAvg_tmp);
  }

  return(0.0);
}

double Bands_ProgressionWeightedMA(
  int position,
  const double &values[],
  const long &weight[],
  int p,
  int firstStepLimit, double firstStepWeight,
  int secondStepLimit, double secondStepWeight,
  int thirdStepLimit, double thirdStepWeight,
  int fourthStepLimit, double fourthStepWeight,
  double dWeight) {

  //--- variables
  double WeightedAvg_dTmp = 0.0;
  double WeightedAvg_tmp = 0.0;
  double prog = 1.0;

  firstStepLimit = firstStepLimit ? firstStepLimit : 1;
  secondStepLimit = secondStepLimit ? secondStepLimit : 7;
  thirdStepLimit = thirdStepLimit ? thirdStepLimit : 14;
  fourthStepLimit = fourthStepLimit ? fourthStepLimit : 21;

  firstStepWeight = firstStepWeight ? firstStepWeight : 10.0;
  secondStepWeight = secondStepWeight ? secondStepWeight : 5.0;
  thirdStepWeight = thirdStepWeight ? thirdStepWeight : 3.0;
  fourthStepWeight = fourthStepWeight ? fourthStepWeight : 1.0;
  dWeight = dWeight ? dWeight : 0.5;

  //--- check for position
  if(position < p) {
    return(WeightedAvg_tmp);
  }

  //--- calcualte WeightedAvg
  for(int i=0; i < p; i++) {
    double w = weight[position - i] || 1;

    if ((i+1) >= 0 && (i+1) <= firstStepLimit) {
      prog = firstStepWeight;
    } else if ((i+1) > firstStepLimit && (i+1) <= secondStepLimit) {
      prog = secondStepWeight;
    } else if ((i+1) > secondStepLimit && (i+1) <= thirdStepLimit) {
      prog = thirdStepWeight;
    } else if ((i+1) > thirdStepLimit && (i+1) <= fourthStepLimit) {
      prog = fourthStepWeight;
    } else {
      prog = dWeight;
    }

    WeightedAvg_dTmp += w * prog;
    WeightedAvg_tmp += values[position - i] * w * prog;
  }

  if (WeightedAvg_dTmp > 0) {
    WeightedAvg_tmp = WeightedAvg_tmp / WeightedAvg_dTmp;
    return(WeightedAvg_tmp);
  }

  return(0.0);
}

enum ENUM_BANDS_TEMPERATURE {
  UPPER = 0,
  MID_UPPER = 1,
  MID = 2,
  MID_LOWER = 3,
  LOWER = 4
};

void Bands_Temperature(
  const double &_stoK[],
  const double &_stoD[],
  const double &_stoTrend[],
  const int _sto_upper_limit,
  const int _sto_lower_limit,
  const double &_pBandUpper[],
  const double &_pBandMidUpper[],
  const double &_pBandLower[],
  const double &_pBandMidLower[],
  const double &_pBandMid[],
  const double &_vBandUpper[],
  const double &_vBandMidUpper[],
  const double &_vBandLower[],
  const double &_vBandMidLower[],
  const double &_vBandMid[],
  const double &_hUp[],
  const double &_hDown[],
  const double &_wUp[],
  const double &_wDown[],
  const double &_cUp[],
  const double &_cDown[],
  const double &price[],
  const int i,
  const int period,
  int& _trend,
  double& _hotUp,
  double& _warmUp,
  double& _coldUp,
  double& _hotDown,
  double& _warmDown,
  double& _coldDown
) {

  // Override return values
  _hotUp = 0.0;
  _warmUp = 0.0;
  _coldUp = 0.0;
  _hotDown = 0.0;
  _warmDown = 0.0;
  _coldDown = 0.0;

  ENUM_DEAL_ENTRY lastTrend = -1;
  double lastHUp = 0.0, lastHDown = 0.0, lastWUp = 0.0, lastWDown = 0.0, lastCUp = 0.0, lastCDown = 0.0;

  // Get last values
  if (i > 0) {
    if (_stoTrend[i-1] >= 0.0) {
      lastTrend = (ENUM_DEAL_ENTRY)(int)_stoTrend[i-1];
    } else {
      lastTrend = (ENUM_DEAL_ENTRY)Bands_FindLastTrend(_stoK, _stoD, i, period);
    }

    if (_hUp[i-1] >= 0.0) {
      lastHUp = _hUp[i-1];
    }

    if (_hDown[i-1] >= 0.0) {
      lastHDown = _hDown[i-1];
    }

    if (_wUp[i-1] >= 0.0) {
      lastWUp = _wUp[i-1];
    }

    if (_wDown[i-1] >= 0.0) {
      lastWDown = _wDown[i-1];
    }

    if (_cUp[i-1] >= 0.0) {
      lastCUp = _cUp[i-1];
    }

    if (_cDown[i-1] >= 0.0) {
      lastCDown = _cDown[i-1];
    }
  }

  // Check if is possible to calculate
  if ((i+1) < period || (lastTrend != DEAL_ENTRY_IN && lastTrend != DEAL_ENTRY_OUT)) {
    return;
  }

  // Calculate trend
  ENUM_BANDS_TEMPERATURE trendPower = MID;

  if (_stoK[i-1] <= _stoD[i-1] && _stoK[i] > _stoD[i]) {
    _trend = DEAL_ENTRY_IN;
  } else if (_stoK[i-1] >= _stoD[i-1] && _stoK[i] < _stoD[i]) {
    _trend = DEAL_ENTRY_OUT;
  } else {
    _trend = lastTrend;
  }

  if (_stoK[i] >= _sto_upper_limit && _trend == DEAL_ENTRY_IN) {
    trendPower = UPPER;
  } else if (_stoK[i] <= _sto_lower_limit && _trend == DEAL_ENTRY_OUT) {
    trendPower = LOWER;
  }

  // Set temperatures
  bool prevLTBothUpper = price[i-1] < _pBandUpper[i-1] && price[i-1] < _vBandUpper[i-1];
  bool prevLTBothMidUpper = price[i-1] < _pBandMidUpper[i-1] && price[i-1] < _vBandMidUpper[i-1];

  bool curGTEOneUpper = price[i] >= _pBandUpper[i] || price[i] >= _vBandUpper[i];
  bool curGTEOneMidUpper = price[i] >= _pBandMidUpper[i] || price[i] >= _vBandMidUpper[i];

  bool prevGTBothLower = price[i-1] > _pBandLower[i-1] && price[i-1] > _vBandLower[i-1];
  bool prevGTBothMidLower = price[i-1] > _pBandMidLower[i-1] && price[i-1] > _vBandMidLower[i-1];

  bool curLTEOneLower = price[i] <= _pBandLower[i] || price[i] <= _vBandLower[i];
  bool curLTEOneMidLower = price[i] <= _pBandMidLower[i] || price[i] <= _vBandMidLower[i];

  bool curGTEOneMid = price[i] >= _pBandMid[i] || price[i] >= _vBandMid[i];
  bool curLTEOneMid = price[i] <= _pBandMid[i] || price[i] <= _vBandMid[i];

  bool prevLTBothMid = price[i-1] < _pBandMid[i-1] && price[i-1] < _vBandMid[i-1];
  bool prevGTBothMid = price[i-1] > _pBandMid[i-1] && price[i-1] > _vBandMid[i-1];

  if (((prevLTBothUpper && curGTEOneUpper)
      || (prevLTBothMidUpper && curGTEOneMidUpper)
      || (lastHUp > 0.0 && price[i] > lastHUp))
      && trendPower == UPPER) {
    _hotUp = price[i];
  } else if (((prevGTBothLower && curLTEOneLower)
            || (prevGTBothMidLower && curLTEOneMidLower)
            || (lastHDown > 0.0 && price[i] < lastHDown))
            && trendPower == LOWER) {
    _hotDown = price[i];
  } else if ((prevLTBothUpper && curGTEOneUpper)
            || (prevLTBothMidUpper && curGTEOneMidUpper)
            || (prevLTBothMid && curGTEOneMid && trendPower == UPPER)
            || (lastWUp > 0.0 && price[i] > lastWUp)) {
    _warmUp = price[i];
  } else if ((prevGTBothLower && curLTEOneLower)
            || (prevGTBothMidLower && curLTEOneMidLower)
            || (prevGTBothMid && curLTEOneMid && trendPower == LOWER)
            || (lastWDown > 0.0 && price[i] < lastWDown)) {
    _warmDown = price[i];
  } else if ((prevLTBothMid && curGTEOneMid) || (lastCUp > 0.0 && price[i] > lastCUp)) {
    _coldUp = price[i];
  } else if ((prevGTBothMid && curLTEOneMid) || (lastCDown > 0.0 && price[i] < lastCDown)) {
    _coldDown = price[i];
  }

  return;
}

int Bands_FindLastTrend(
  const double &_stoK[],
  const double &_stoD[],
  const int i,
  const int period) {
  ENUM_DEAL_ENTRY output = -1;

  if ((i+1) < period) {
    return output;
  }

  for (int j = 1; j < period; j++) {
    if (_stoK[i-j] > _stoD[i-j]) {
      output = DEAL_ENTRY_IN;
      break;
    } else if (_stoK[i-j] < _stoD[i-j]) {
      output = DEAL_ENTRY_OUT;
      break;
    }
  }

  return output;
}

