class Parser:
  def __init__(self, inpt, output=None):
    self.input = inpt
    self.output = output

  @classmethod
  def convert_record_to_dict(self, query):
    for rec in query:
      yield rec.info

  def get_query(self):
    bf = bovespa.File(self.input)
    return bf.query()

  def get_dataframe(self):
    return pd.DataFrame(self.convert_record_to_dict(self.get_query()))