#!/usr/bin/python3

import configparser

config = configparser.ConfigParser()
config.read('app.ini')

for key, value in config['names'].items():
    print("{}={}".format('_'.join(['app', key]).upper(), value))
