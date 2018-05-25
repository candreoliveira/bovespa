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

    def balance(self, start, end):
      def can_record(dt, start, end):
        return dt >= start and dt <= end
        
      totalCost, totalRevenue, totalResult = 0, 0, 0
      output = {
        "cost": [],
        "revenue": [],
        "result": [],
        "datetime": [],
        "custody": {}
      }

      sorted_positions = sorted(self.positions, key=lambda x: x.count, reverse=False)
      first_position = sorted_positions[0]
      last_position = sorted_positions[len(sorted_positions)-1]

      if first_position.type != "buy" or last_position.type != "sell":
        raise errs.AccountPositionsError("First and last positions must be buy and sell.")

      for p in sorted_positions:
        for today in daterange(first_position.datetime, last_position.datetime):
          fdatetime = today.strftime("%Y-%m-%d-%H-%M-%S-%f")

          if can_record(today, start, end):
            if p.datetime == today:
              print()
            else:
              output["cost"].append(0.0)

              revenue = {}
              for stock in output["custody"].keys():
                len_custody = len(output["custody"][stock])
                len_datetime = len(output["datetime"])
                last_custody = output["custody"][stock][len_custody-1] if len_custody > 0 else 0
                last_datetime = output["datetime"][len_datetime-1] if len_datetime > 0 else None
                
                output["custody"][stock].append(last_custody)
                revenue[stock] = (quotation.get_price(stock, today) - quotation.get_price(stock, last_datetime)) * last_custody

              output["revenue"].append(reduce(lambda cum, cur: cum + cur, revenue[stock].values()))
              output["result"].append()

            output["datetime"].append(fdatetime)

            

      return output