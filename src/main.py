#####################################################################################################
#####################################################################################################
####################### Import dependencies
#####################################################################################################
#####################################################################################################

import bovespa
import pandas as pd
import csv
import fnmatch
import re
import math
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import ipywidgets as widgets
from datetime import datetime
from __future__ import print_function
from ipywidgets import interact, interactive, fixed, interact_manual
from pandasql import sqldf

from configparser import ConfigParser
from os import listdir, path
import utils
import parser

# Read Config
config = ConfigParser()
config.read([path.join(config.get("DEFAULT", "config_directory"), config.get("DEFAULT", "config_file"))])

# Parse File
p = parser.Parser(path.join(config.get("DEFAULT", "data_directory"), config.get("DEFAULT", "data_file")))
q = p.get_query()
