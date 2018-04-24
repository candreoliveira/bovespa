import argparse
import bovespa
import pandas as pd
import csv

parser = argparse.ArgumentParser(description='Process bovespa historical data.')
parser.add_argument('--input', type=str, required=True, help='Input file to process.')
parser.add_argument('--output', type=str, help='Output to filte to write.')
parser.add_argument('--stock1', type=str, help='Stock 1 to process.')
parser.add_argument('--stock2', type=str, help='Stock 2 to process.')

class Parser:
    def __init__(self, input, output=None):
        self.input = input
        self.output = output

    def convert_record_to_dict(self, query):
        for rec in query:
            yield rec.info

    def get_query(self):
        bf = bovespa.File(self.input)
        return bf.query()

    def get_data_frame(self):
        return pd.DataFrame(self.convert_record_to_dict(self.get_query()))

    # def process_file(self):
        
    #         for rec in self.from_record_to_dict():
    #             print('<{}, {}, {}>'.format(rec.date, rec.stock_code, rec.price_close))

    # def write_output:
    #     with open(self.output, "w") as csvfile:
    #         fieldnames = bovespa.layout.stockquote.keys()
    #         writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    #         writer.writeheader()
            
    #         for rec in bf.query(stock=self.stock):
    #             writer.writerow(dict(rec.info))            
            
args = parser.parse_args()
parser = Parser(args.input, args.output)

bov_df = parser.get_data_frame()
# print(bov_df[bov_df.CODNEG == "BBDC4"])

df_stock1 = bov_df[bov_df.CODNEG == args.stock1]
df_stock1.index = range(len(df_stock1))
df_stock2 = bov_df[bov_df.CODNEG == args.stock2]
df_stock2.index = range(len(df_stock2))

df = pd.DataFrame()
df['DATA'] = df_stock1.DATPRG
df['FORMULA'] = f'{args.stock1}/{args.stock2}'
df[args.stock1] = df_stock1.PREULT
df[args.stock2] = df_stock2.PREULT
df['RATIO'] = df_stock1.PREULT/df_stock2.PREULT

mean = pd.Series.mean(df.RATIO)
std = pd.Series.std(df.RATIO)

df['STD'] = mean
df['MEAN'] = std

print(df)