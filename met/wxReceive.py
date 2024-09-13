'''
Read in data from the airmax weather station and output to a file.

'''
import logging
import serial
import datetime as dt
import argparse
import gzip
import os
import glob
import time

from math import sqrt, sin, cos, pi

logging.basicConfig(level=logging.DEBUG,
					format='%(asctime)s %(levelname)-8s %(message)s',
					datefmt='%y-%m-%d %H:%M')

NODATE = ' 9999 99 99 99 99 99'
NOVAL = 9999.9


def nmea2dict(textout, din):
	'''
	Update the dictionary din with the datat from textout
	'''
	checkdata = lambda x: NOVAL if x == '' else float(x)
	key = textout.split(',')[0].strip('$').split('*')[0]
	if 'WIMDA' in key:
		tmp = textout.split(',')
		if len(tmp) >= 20:
			temperature = checkdata(tmp[5])
			relative_humidity = checkdata(tmp[9])
			wind_direction_T = checkdata(tmp[13])
			wind_speed_m = checkdata(tmp[19])
			din['TD'] = temperature
			din['HR'] = relative_humidity
			din['WD'] = wind_direction_T
			din['WS'] = wind_speed_m
		else:
			logging.info('Corrupt input data: less than 20 fields in text split')
			
	elif ('YXXDR' in key) and ('STNP' in textout):
		pressure = checkdata(textout.split(',')[14])
		pressure = pressure if pressure == 9999.9 else pressure * 1e3
		din['PR'] = pressure
	elif 'GPZDA' in key:
		gpstime = textout.split(',')[1:5]
		gpstime[0] = gpstime[0][:-3]
		t = ''.join(gpstime)
		tfmt = '%H%M%S%d%m%Y'
		try:
			ctime = dt.datetime.strptime(t, tfmt)
			din['epoch'] = ctime
			din['ts'] = ctime.hour * 3600 + ctime.minute * 60 + ctime.second
			din['date'] = ctime.strftime(' %Y %m %d %H %M %S')
		except Exception as e:
			din['date'] = NODATE
			logging.error(e)			
	return din


def lla2ecef(lat, lon, alt):
	a = 6378137
	a_sq = a ** 2
	e = 8.181919084261345e-2
	e_sq = e ** 2
	b_sq = a_sq * (1 - e_sq)

	lat = lat * pi/180
	lon = lon * pi/180

	N = a / sqrt(1 - e_sq * sin(lat) ** 2)
	x = (N + alt) * cos(lat) * cos(lon)
	y = (N + alt) * cos(lat) * sin(lon)
	z = ((b_sq / a_sq) * N + alt) * sin(lat)

	return x, y, z


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("--interval", help="Sampling interval in seconds. Default: 60", 
						type=int, default=60)
	parser.add_argument("--debug",    help="Creates files every hour for debugging.",
						action="store_true", default=False)
	parser.add_argument("--name",     help="Name of the station to use. Default: STNM",
						type=str, default="STNM")
	parser.add_argument("--session",  help="Session length in minutes (multiple of 60). Default: 1440",
						type=int, default=1440)
	parser.add_argument("--country",  help="Country code. Default: UNK",
						type=str, default='UNK')
	parser.add_argument("--dir",      help="Output directory. Default: CWD",
						type=str, default='./')
	parser.add_argument("--serial",   help="Serial number to write in RINEX file. Default: UNKNOWN",
						type=str, default='UNKNOWN')									
	args = parser.parse_args()
	rlogger = logging.getLogger('')
	rlogger.setLevel(logging.DEBUG if args.debug else logging.INFO)
	
	interval = args.interval # Data interval in seconds
	ses_len  = args.session  # length of the session (how many minutes)
	stnm     = args.name     # station name (4-char)
	ccod     = args.country  # country code for RINEX3
	serial_n = args.serial   # serial number of weather station
	out_dir  = args.dir      # location of output RINEX
	
	logging.info('Starting wxReceive - config follows:')
	logging.info('station name   %s ' % stnm)
	logging.info('Interval       %i ' % interval)
	logging.info('Session length %i ' % ses_len)
	logging.info('Country code   %s ' % ccod)
	logging.info('Serial number  %s ' % serial_n)
	logging.info('Output dir     %s ' % out_dir) 
	
	# check is out dire exists, otherwise create
	if not os.path.isdir(out_dir):
		os.makedirs(out_dir)
	
	# check that the session length is valid
	if ses_len < 5 or ses_len % 5:
		raise(Exception('Error: session length should be multiple of 60 minutes.'))
	else:
		if ses_len >= 1440:
			file_period = f'{ses_len / 1440:02.0f}D'
		elif ses_len >= 60:
			file_period = f'{ses_len / 60:02.0f}H'
		elif ses_len >= 1:
			file_period = f'{ses_len:02.0f}M'

	# check that the interval is valid
	if interval >= 3600:
		data_freq = f'{interval / 3600:02.0f}H'
	elif interval >= 60:
		data_freq = f'{interval / 60:02.0f}M'
	else:
		data_freq = f'{interval:02.0f}S'
	
	obstypes = [' '*4 + 'PR', ' '*4 + 'TD', ' '*4 + 'HR', ' '*4 + 'WD', ' '*4 + 'WS']

	# write the header
	hdr = ''
	hdr += f'{3.05:>9.2f}' + ' '*11 + f'{"METEOROLOGICAL DATA":<20s}' + ' '*20 + 'RINEX VERSION / TYPE\n'
	hdr += 'wxReceive.py' + ' '*8 + 'OSU' + ' '*17
	hdr += str(dt.datetime.now().strftime('%d-%b-%y %H:%M')) + ' '*5
	hdr += 'PGM / RUN BY / DATE\n'
	# hdr += f'{"Rinex 3.05 met file is the same as 2.11": <60s}COMMENT\n'
	hdr += f'{stnm + "00" + ccod.upper():<60s}MARKER NAME\n'
	obs = ('').join(obstypes)
	hdr += f'{5: >6d}' + f"{obs: <54s}"
	hdr += "# / TYPES OF OBSERV\n"
	hdr += f'{"AIRMAR": <20s}{"150WXS": <26s}{0.5: >7.1f}{" ": <4s}PR '
	hdr += "SENSOR MOD/TYPE/ACC\n"
	hdr += f'{"AIRMAR": <20s}{"150WXS": <26s}{1.1: >7.1f}{" ": <4s}TD '
	hdr += "SENSOR MOD/TYPE/ACC\n"
	hdr += f'{"AIRMAR": <20s}{"150WXS": <26s}{5.1: >7.1f}{" ": <4s}HR '
	hdr += "SENSOR MOD/TYPE/ACC\n"
	hdr += f'{"AIRMAR": <20s}{"150WXS": <26s}{3.1: >7.1f}{" ": <4s}WD '
	hdr += "SENSOR MOD/TYPE/ACC\n"
	hdr += f'{"AIRMAR": <20s}{"150WXS": <26s}{0.5: >7.1f}{" ": <4s}WS '
	hdr += "SENSOR MOD/TYPE/ACC\n"
	hdr += f'{"SERIAL NUMBER: " + serial_n:<60s}COMMENT\n'
	hdr += f'{"Wind speed accuracy 5% @ 10 m/s": <60s}COMMENT\n'
	
	datadict = {'PR': 9999.9, 'TD': 9999.9, 'HR': 9999.9, 'WD': 9999.9, 'WS': 9999.9, 'date': NODATE, 'epoch': dt.datetime(9999, 12, 31, 0, 0, 0), 'ts': 9999}
	s = serial.Serial('/dev/ttyS0', 4800)
	gpstime = ''
	
	# set the tic to obtain the fix time
	t1 = dt.datetime.now()
	
	logging.info('Locking to GPS Time')
	while gpstime == '':
		# read the serial port
		try:
			textout = s.readline().decode('utf-8')
			logging.debug(textout.strip('\n'))
			# split the text and remove the checksum and $ 
			key = textout.split(',')[0].strip('$').split('*')[0]
			# is this message time?
			if 'GPZDA' in key:
				# log message
				logging.info(textout.strip('\n'))
				# split the gpstime fields
				gpstime = textout.split(',')[1:5]
				try:
					gpstime[0] = gpstime[0][:-3]
					t = ''.join(gpstime)
					tfmt = '%H%M%S%d%m%Y'				
					ctime = dt.datetime.strptime(t, tfmt)
					# put the time in the data dictionary
					datadict['epoch'] = ctime
				except:
					# invalid time, revert gpstime
					logging.info('Sleeping 10 seconds while waiting for fix...')
					time.sleep(10)
					gpstime = ''
					pass
		except Exception as e:
			logging.info('ERROR while reading serial (gpstime): %s' % str(e))
			s = serial.Serial('/dev/ttyS0', 4800)
			pass
				
	logging.debug(f'gpstime: {gpstime}')
	# caluculate the time to fix
	t2 = dt.datetime.now()
	logging.debug(f'Time to fix: {t2 - t1}')
	
	# let lat lon and h position
	lat = 99; lon = 999; h   = -99
	x   =  0; y   =   0; z   = 0
	
	logging.info('Getting station coordinate')
	# loop until valid latitude
	while lat > 90:
		# read the serial port
		try:
			# read serial port
			textout = s.readline().decode('utf-8')
			logging.debug(textout.strip('\n'))
			key = textout.split(',')[0].strip('$').split('*')[0]
			# is message position?
			if 'GPGGA' in key:
				logging.info(textout.strip('\n'))
				try:
					lla = textout.split(',')[1:10]
					logging.debug('Extracted GPGGA message: ' + ' '.join(lla))
				
					LS = -1 if lla[2] == 'S' else 1
					LW = -1 if lla[4] == 'W' else 1
					
					lat = (float(lla[1][0:2]) + float(lla[1][2:]) / 60) * LS
					lon = (float(lla[3][0:3]) + float(lla[3][3:]) / 60) * LW
					h   = float(lla[8])
					
					logging.debug('Values: ' + str(lat) + ' ' + str(lon) + ' ' + str(h))
					
					# convert to XYZ
					x, y, z = lla2ecef(lat, lon, h)
					
					logging.debug('ECEF Values: ' + str(x) + ' ' + str(y) + ' ' + str(z))
				except Exception as e:
					logging.info('Sleeping 10 seconds while waiting for fix...')
					time.sleep(10)
					pass
		except Exception as e:
			logging.info('ERROR while reading serial (latitude longitude): %s' % str(e))
			pass
			
	stnxyzh = [x, y, z, h]
	
	# finish writing header
	hdr += f'{stnxyzh[0]: 14.4f}{stnxyzh[1]: 14.4f}{stnxyzh[2]: 14.4f}{stnxyzh[3]: 14.4f} PR SENSOR POS XYZ/H\n'
	hdr += f'{" ":60s}END OF HEADER\n'
	
	# log the header
	logging.info(hdr)
	
	# gzip any other previously created RINEX
	# this is in case the program or Raspberry crashed and some RINEX file still exists
	rnx = glob.glob(os.path.join(out_dir, '*.rnx')) + glob.glob(os.path.join(out_dir, '*.gz'))
	for i, f in enumerate(rnx):
		if f[-3:] == 'rnx':
			# open and compress
			with open(f, 'rb') as f_in, gzip.open(f + '.gz', 'wb') as f_out:
				f_out.writelines(f_in)
				logging.info(f'{"Compressing previously uncompressed file " + f}')
			# remove original file
			os.remove(f)
		else:
			# remove the gz and leave it in the list so that file is not recreated if logging stops more than once
			rnx[i] = f[:-3]
			logging.debug(f'{"Adding to the list previously zipped file " + rnx[i]}')
	
	record_data = False
	datastr = ''
	fout = ''
	
	while True:
		# check if a previous file exists and compress it
		if os.path.isfile(fout):
			# open and compress
			with open(fout, 'rb') as f_in, gzip.open(fout + '.gz', 'wb') as f_out:
				f_out.writelines(f_in)
			# remove original file
			os.remove(fout)
		
		# Generate a new filename
		# get the session start even if not starting at the exact minute
		# unless file exists in which case, we fall back to using ctime
		# this avoids overwriting data if the process restarts
		ses_date = ctime + dt.timedelta(minutes=-((ctime.hour * 60 + ctime.minute) % ses_len))
		# print the filename
		fout = f"{stnm:<06s}{ccod.upper():<03s}_R_{ses_date.strftime('%Y%j%H%M')}_{file_period}_{data_freq}_MM.rnx"
		# add the output directory
		fout = os.path.join(out_dir, fout)
		
		# check if file exists and if it was already gzipped
		if os.path.isfile(fout) or fout in rnx:
			fout = f"{stnm:<06s}{ccod.upper():<03s}_R_{ctime.strftime('%Y%j%H%M')}_{file_period}_{data_freq}_MM.rnx"
			# add the output directory
			fout = os.path.join(out_dir, fout)
		
		logging.info(f'Starting new file: {fout}')
		oldtime = datadict['epoch']
		
		# write a zipped file directly
		with open(fout, 'w') as f:
			f.write(hdr)
			# a previous data frame was ready to be printed, but there was a session change
			# write now
			if record_data:
				f.write(datastr)
				logging.debug(datastr)
		
		# initialize variable
		teststr = True
		
		while teststr > 0:
			# testfmt = '%H' if args.debug else '%j'

			lastts  = datadict['ts']
			
			while datadict['ts'] == lastts:
				try:
					textout = s.readline().decode('utf-8')
					datadict = nmea2dict(textout, datadict)
				except ValueError:
					# try-catch for error detected in RDCM
					# ValueError: could not convert string to float: 'A*15\r\n'
					pass
				
			datastr = ''
			datastr += datadict['date']
			datastr += f"{datadict['PR']: 7.1f}"
			datastr += f"{datadict['TD']: 7.1f}"
			datastr += f"{datadict['HR']: 7.1f}"
			datastr += f"{datadict['WD']: 7.1f}"
			datastr += f"{datadict['WS']: 7.1f}"
			datastr += "\n"
			
			record_data = not datadict['ts'] % interval
			
			# test if within session time
			# this will return true if time mod session len is not zero
			# but it returns false for an entire minute
			teststr = (datadict['epoch'].hour * 60 + datadict['epoch'].minute) % ses_len
			ctime   = datadict['epoch']
			logging.debug('datadict: ' + str(datadict['epoch'].hour * 60 + datadict['epoch'].minute) + ' % ' + str(ses_len) + ' = ' + str(teststr))
			# so, we also compare datadict['epoch'] and oldtime and if they are equal
			# and teststr is false, we force it to true so that we don't escape the loop
			if not teststr and oldtime.strftime('%Y%m%d%H%M') == datadict['epoch'].strftime('%Y%m%d%H%M'):
				teststr = True
			
			if record_data and teststr:
				with open(fout, 'a') as f:
					f.write(datastr)
				logging.debug(datastr)
							
					
if __name__ == '__main__':
	main()
