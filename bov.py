import argparse
import bovespa
import csv

parser = argparse.ArgumentParser(description='Process bovespa historical data.')
parser.add_argument('--file', type=str, required=True, help='File to process.')
parser.add_argument('--stock', type=str, help='Stock to process.')

class Parser:
    def __init__(self, file):
        self.file = file

    def process_file(self, output=None):
        bf = bovespa.File(args.file)

        if output and type(output) is str:
            with open(output, "w") as csvfile:
                fieldnames = bovespa.layout.stockquote.keys()
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                
                for rec in bf.query():
                    writer.writerow(dict(rec.info))
        else:
            for rec in bf.query():
                print('<{}, {}, {}>'.format(rec.date, rec.stock_code, rec.price_close))
            

args = parser.parse_args()
parser = Parser(args.file)
parser.process_file("output.csv")