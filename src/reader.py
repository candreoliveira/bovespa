import re
import fnmatch
import select
from os import listdir, path

class Reader(select.Select):
  @staticmethod
  def get_files(where, regex):
    return sorted([name for name in listdir(where) if re.compile(fnmatch.translate(regex), re.IGNORECASE).match(name)])