from .. import errs.errs as errs
import math

def lots_by_amount(amount, lot_size, price):
  lot_price = lot_size * price
  lot_qtd = math.floor(amount / lot_price)
  return lot_qtd, round(lot_price, 3)

def revenue(**kwargs):
  Series     = kwargs.get("Series")
  df         = kwargs.get("dataframe")
  date_attr  = kwargs.get("date_attr")
  price_attr = kwargs.get("price_attr")
  buy_date   = kwargs.get("buy_date") or df[date_attr][0])
  sell_date  = kwargs.get("sell_date") or df[date_attr][df[date_attr].size - 1])
  ini_amount = kwargs.get("amount")
  comission  = kwargs.get("comission")
  lot_size   = kwargs.get("lot_size")
  stop       = kwargs.get("stop")
  start      = kwargs.get("start")

  if not (Series and df and date_attr and price_attr and buy_date and sell_date and ini_amount and comission and lot_size and stop and start):
    raise errs.ArgumentError("Error initializing revenue {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}"
      .format(Series, df, date_attr, price_attr, buy_date, sell_date, ini_amount, comission, lot_size, stop, start))

  Revenue = Series(None, index = df.index, name = (kwargs.get("revenue_name") or "REVENUE_NAME"))
  Result = Series(None, index = df.index, name = (kwargs.get("result_name") or "RESULT_NAME"))
  Cost = Series(None, index = df.index, name = (kwargs.get("cost_name") or "COST_NAME"))
  Stocks = Series(0, index = df.index, name = (kwargs.get("stocks_name") or "STOCKS_NAME"))

  # Calculate first investment
  buy_line = df[df[date_attr] == buy_date]
  idx = buy_line.index.item()
  lot_qtd, lot_price = lots_by_amount(ini_amount, lot_size, buy_line[price_attr]).item())

  Stocks[idx]  = lot_qtd * lot_size
  Revenue[idx] = 0.0
  Cost[idx]    = -comission
  Result[idx]  = ini_amount - (lot_price * lot_qtd) + Cost[idx].item()

  for idx, value in df[np.logical_and(df[date_attr] > buy_date, df[date_attr] <= sell_date)].iterrows():
    previous_price     = (df.loc[idx-1][price_attr]).item()
    lot_price          = value[price_attr] * lot_size
    stocks             = Stocks[idx-1].item()
    Revenue[idx]       = (value[price_attr] - previous_price) * stocks
    result             = Result[idx-1].item() + Revenue[idx].item()
    cost               = 0.0
    qtd_buy_sell       = 0

    # Buy more or close position
    if value[date_attr] == sell_date:
      cost -= comission
      result += stocks * value[price_attr]
      stocks = 0
      lot_qtd = 0

    elif start and result >= (start * ini_amount) and result >= lot_price:
      qtd_buy_sell = math.floor(result / lot_price)
      lot_qtd      = lot_qtd + qtd_buy_sell
      cost        -= comission
      result      -= lot_price * qtd_buy_sell

    Result[idx] = result + cost
    Cost[idx]   = cost
    Stocks[idx] = lot_size * lot_qtd

  return pd.concat([df[date_attr], Result, Revenue, Cost, Stocks], join='outer', axis=1)

def revenue_with_ratio(self, pd, df, date_attr, stock1_price_attr, stock2_price_attr, bb_ratio_attr, bb_base_attr, bb_trend_attr, **kwargs):
  buy_date = (kwargs.get("buy_date") or df[date_attr][0])
  sell_date = (kwargs.get("sell_date") or df[date_attr][df[date_attr].size - 1])
  ini_amount = (kwargs.get("amount") or 10000.0)
  comission = (kwargs.get("comission") or 5.0)
  lot_size = (kwargs.get("lot_size") or 100)
  stop = (kwargs.get("stop") or None)
  start = (kwargs.get("start") or None)

  Revenue = Series(None, index = df.index, name = (kwargs.get("revenue_name") or "REVENUE_NAME"))
  Result = Series(None, index = df.index, name = (kwargs.get("result_name") or "RESULT_NAME"))
  Cost = Series(None, index = df.index, name = (kwargs.get("cost_name") or "COST_NAME"))
  Stocks = Series(0, index = df.index, name = (kwargs.get("stocks_name") or "STOCKS_NAME"))

  # It defines the first buy of stock for net income calculation
  buy_line  = df[df[date_attr] == buy_date]

  if (buy_line[bb_base_attr]).item() and ((buy_line[bb_ratio_attr]).item() > (buy_line[bb_base_attr]).item()):
    trend = 1
  else:
    trend = -1

  price_attr = stock1_price_attr if trend == -1 else stock2_price_attr

  # Calculate first investment
  lot_price    = (buy_line[price_attr]).item() * lot_size
  lot_qtd      = math.floor(ini_amount / lot_price)
  idx          = buy_line.index.item()

  Stocks[idx]  = lot_qtd * lot_size
  Revenue[idx] = 0.0
  Cost[idx]    = -comission
  Result[idx]  = ini_amount - (lot_price * lot_qtd) + Cost[idx].item()

  for idx, value in df[np.logical_and(df[date_attr] > buy_date, df[date_attr] <= sell_date)].iterrows():
    previous_price     = (df.loc[idx-1][price_attr]).item()
    lot_price          = value[price_attr] * lot_size
    stocks             = Stocks[idx-1].item()
    Revenue[idx]       = (value[price_attr] - previous_price) * stocks
    result             = Result[idx-1].item() + Revenue[idx].item()
    cost               = 0.0
    qtd_buy_sell       = 0

    # Change, buy more or close position
    if value[date_attr] == sell_date:
      cost -= comission
      result += stocks * value[price_attr]
      stocks = 0
      lot_qtd = 0

    elif (value[bb_trend_attr] == 1 and trend == -1) or (value[bb_trend_attr] == -1 and trend == 1):
      trend = 1 if trend == -1 else -1
      price_attr = stock2_price_attr if trend == 1 else stock1_price_attr

      temp_cost      = cost - comission
      temp_result    = result + temp_cost + (lot_price * lot_qtd)
      temp_lot_price = value[price_attr] * lot_size
      temp_lot_qtd   = math.floor(temp_result / temp_lot_price)

      # Can sell and buy?
      if (temp_lot_qtd > 0):
        # Sell
        cost    = temp_cost
        result  = temp_result
        stocks  = 0
        lot_qtd = 0

        # Buy
        lot_price = temp_lot_price
        lot_qtd   = temp_lot_qtd
        amount    = result - (lot_price * lot_qtd)
        prev_cost = cost
        cost      -= comission
        result    -= (lot_price * lot_qtd) + prev_cost

    elif start and result >= (start * ini_amount) and result >= lot_price:
      qtd_buy_sell = math.floor(result / lot_price)
      lot_qtd      = lot_qtd + qtd_buy_sell
      cost        -= comission
      result      -= lot_price * qtd_buy_sell

    Result[idx] = result + cost
    Cost[idx]   = cost
    Stocks[idx] = lot_size * lot_qtd

  return pd.concat([df[date_attr], Result, Revenue, Cost, Stocks], join='outer', axis=1)

def bbands(self, df, date_attr, price_attr, n, nstd, nresult, **kwargs):
  buy_date = (kwargs.get("buy_date") or df[date_attr][0])
  sell_date = (kwargs.get("sell_date") or df[date_attr][df[date_attr].size - 1])
  comission = (kwargs.get("comission") or 5.0)

  MA = Series(df[price_attr].rolling(window=n).mean())
  MSD = Series(df[price_attr].rolling(window=n).std())

  Base = Series(MA, name = (kwargs.get("base_name") or "BASE"))
  Middle_upper = Series(MA + MSD * nstd/2, name = (kwargs.get("middle_upper_name") or "MIDDLE_UPPER"))
  Middle_lower = Series(MA - MSD * nstd/2, name = (kwargs.get("middle_lower_name") or "MIDDLE_LOWER"))
  Upper = Series(MA + MSD * nstd, name = (kwargs.get("upper_name") or "UPPER"))
  Lower = Series(MA - MSD * nstd, name = (kwargs.get("lower_name") or "LOWER"))

  Cost = Series(0, index = Lower.index, name = (kwargs.get("cost_name") or "COST"))
  Trend = Series(0, index = Lower.index, name = (kwargs.get("trend_name") or "TREND"))
  Result = Series(None, index = Lower.index, name = (kwargs.get("result_name") or "RESULT"))

  last_result = None
  last_idx = 0
  last_trend = None

  for idx, value in df[np.logical_and(df[date_attr] > buy_date, df[date_attr] <= sell_date)].iterrows():
    if idx >= n:
      # Trend/Result calculation
      if ((last_trend != 1) and
        ((df[price_attr][idx] > Upper[idx]) or
        ((last_trend != 1) and ((idx - last_idx) >= nresult) and (df[price_attr][idx] > Middle_upper[idx])) or
        ((last_trend != 1) and ((idx - last_idx) >= 2*nresult) and (df[price_attr][idx] > Base[idx])))):
        Trend[idx] = 1
      elif ((last_trend != -1) and
        ((df[price_attr][idx] < Lower[idx]) or
        ((last_trend != -1) and ((idx - last_idx) >= nresult) and (df[price_attr][idx] < Middle_lower[idx])) or
        ((last_trend != -1) and ((idx - last_idx) >= 2*nresult) and (df[price_attr][idx] < Base[idx])))):
        Trend[idx] = -1

      # Lower/Upper adjust based on trend
      if (Trend[idx] == 1) and (Lower[idx] < Lower[idx-1]):
        Lower[idx] = Lower[idx-1]
      elif (Trend[idx] == -1) and (Upper[idx] > Upper[idx-1]):
        Upper[idx] = Upper[idx-1]

      # Update result
      if (Trend[idx] != 0):
        Result[idx] = df[price_attr][idx]
        Cost[idx] = -2 * comission
        last_result = Result[idx]
        last_idx = idx
        last_trend = Trend[idx]

  return pd.concat([df[date_attr], Upper, Middle_upper, Base, Middle_lower, Lower, Result, Trend, Cost], join='outer', axis=1)