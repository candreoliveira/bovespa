class Quotation:
  quotations = []

  def __init__(self, datetime, stock):
    self.datetime = datetime
    self.stock = stock

  @staticmethod
  def add_quotation(quot):
    Quotation.quotations.append(quot)

  @staticmethod
  def get_price(stock, datetime):
    return list(filter(lambda x: x.datetime == datetime and x.stock == stock, Quotation.quotations))[0]