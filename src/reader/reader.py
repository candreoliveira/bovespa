import re
import fnmatch
from .. import select.select as select
from os import listdir, path

class Reader(select.Select):
  @classmethod
  def get_files(self, where, regex):
    return sorted([name for name in listdir(where) if re.compile(fnmatch.translate(regex), re.IGNORECASE).match(name)])