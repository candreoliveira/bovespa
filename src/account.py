import errs
import position
import quotation
from utils import daterange
from functools import reduce

class Account:
    def __init__(self, amount, positions):
      self.amount = amount
      self.positions = positions

    def add_position(self, pos):
      if pos.__class__ != position.Position:
        raise errs.ArgumentError("Add position didn't receive a position {0}.".format(pos))
      self.positions.append(position)

    def remove_position(self, pos):
      if pos.__class__ != position.Position:
        raise errs.ArgumentError("Remove position didn't receive a position {0}.".format(pos))
      self.positions = list(filter(lambda x: x.id != pos.id, self.positions))

    def get_position(self, datetime):
      return list(filter(lambda x: x.datetime == datetime, self.positions))[0]

    # Considera-se uma compra efetivada no fim do dia, ou seja, dia de compra não tem possível lucro/prejuízo.
    def balance(self, start, end):
      def can_record(dt, start, end):
        return dt >= start and dt <= end

      output = {
        "cost": [],
        "revenue": [],
        "result": [],
        "datetime": [],
        "custody": {},
        "total": {
          "cost": 0,
          "revenue": 0,
          "result": 0
        }
      }

      sorted_positions = sorted(self.positions, key=lambda x: x.datetime, reverse=False)
      first_position = sorted_positions[0]
      last_position = sorted_positions[len(sorted_positions)-1]

      if first_position.type != "buy" or last_position.type != "sell":
        raise errs.AccountPositionsError("First and last positions must be buy and sell.")

      for today in daterange(first_position.datetime, last_position.datetime):
        fdatetime = today.strftime("%Y-%m-%d-%H-%M-%S-%f")
        p = self.get_position(today)
        x, c = None, None

        if p and p.type == "buy":
          x -= (p.price * p.quantity)
          c = p.comission
        elif p and p.type == "sell":
          x += (p.price * p.quantity)
          c = p.comission
        else:
          x = 0.0
          c = 0.0

        if can_record(today, start, end):
          output["cost"].append(c)
          output["total"]["cost"] += c

          revenue = {}
          for stock in output["custody"].keys():
            # Get last date and last custody
            len_custody = len(output["custody"][stock])
            len_datetime = len(output["datetime"])
            last_custody = output["custody"][stock][len_custody-1] if len_custody > 0 else 0
            last_datetime = output["datetime"][len_datetime-1] if len_datetime > 0 else None

            # Calculate revenue per stock
            revenue[stock] = (quotation.Quotation.get_price(stock, today) - quotation.Quotation.get_price(stock, last_datetime)) * last_custody

            # Keep the same custody and append
            if p.datetime == today and p.type == "buy":
              output["custody"][stock].append(last_custody + p.quantity)
            elif p.datetime == today and p.type == "sell":
              output["custody"][stock].append(last_custody - p.quantity)
            else:
              output["custody"][stock].append(last_custody + p.quantity)

          # Sum all stocks
          r = reduce(lambda cum, cur: cum + cur, revenue.values(), 0.0)
          output["total"]["revenue"] += r
          output["revenue"].append(r)

          # Sum all results
          t = r + x - c
          output["total"]["result"] += t
          output["result"].append(t)
          output["datetime"].append(fdatetime)

      return output