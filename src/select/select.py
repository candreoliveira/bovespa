import ipywidgets as widgets

class Select:
  def __init__(self, option=None, dropdown=None):
    self.option = option
    self.dropdown = dropdown

  def get_dropdown(self, options, value, description="Option:"):
    if not self.dropdown:
      w = widgets.Dropdown(options=options,description=description,value=value)
      w.observe(self.on_change)
      self.dropdown = w
      self.option = w.value

      return self.dropdown

  def on_change(self, change):
    if change.name == "value" and change.type == "change":
      self.option = change.new