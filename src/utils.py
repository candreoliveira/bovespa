from datetime import timedelta, date

def daterange(start_date, end_date):
  for n in range(int ((end_date - start_date).days)):
    yield start_date + timedelta(n)

def is_notebook():
  try:
    return get_ipython().__class__.__name__ in ["ZMQInteractiveShell", "TerminalInteractiveShell"]
  except NameError:
    return False