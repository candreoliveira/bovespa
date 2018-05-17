from .. import errs.errs as errs, position.position as position

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

    def balance(start, end):
      sorted_positions =
      def calculate(cum, cur):
        if cur.type == "sell"
        elif cur.type == "buy":

      return reduce(calculate, self.positions, self.amount)