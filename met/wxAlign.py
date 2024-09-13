'''
Read in data from the airmax weather station and output to a file.

'''
import logging
import serial
import datetime as dt
import argparse
import gzip
import os

from math import sqrt, sin, cos, pi

logging.basicConfig(level=logging.DEBUG,
					format='%(asctime)s %(levelname)-8s %(message)s',
					datefmt='%y-%m-%d %H:%M')

    
def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("--debug", help="Creates files every hour for debugging.",
						action="store_true", default=False)
										
	args = parser.parse_args()
	rlogger = logging.getLogger('')
	rlogger.setLevel(logging.DEBUG if args.debug else logging.INFO)
	
	s = serial.Serial('/dev/ttyS0', 4800)

	while True:
		# read the serial port
		try:
			textout = s.readline().decode('utf-8')
			# print the whole message in debug mode
			logging.debug(textout.strip('\n'))
			# split the text and remove the checksum and $ 
			key = textout.split(',')[0].strip('$').split('*')[0]
			# is this message heading?
			if 'HCHDT' in key:
				# split the gpstime fields
				heading = textout.split(',')[1]
				logging.debug(heading)
				try:
					logging.info('Align until you read ~0 degrees: ' + heading)
				except:
					pass
		except Exception as e:
			logging.info('ERROR while reading serial (HCHDT): %s' % str(e))
			pass
			
					
if __name__ == '__main__':
	main()

