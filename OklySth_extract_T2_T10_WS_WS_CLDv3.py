#            Tasks
# Read WRFdaily and WRFout
# Extract wind speed and wind direction at 10m and 30m
# Export to text format
#
# Originaly adapted from NCL extractlT2T10WSWD.ncl
# Date  # April2019

# Adapted by Alyce Sala Tenna to suit wrf-python
# Date  # 10 October 2020
# Contact # alyce.salatenna@ghd.com

###########################################################################################

# begin
import numpy as np
import Nio
import Ngl
import wrf
import xarray
import pandas as pd

# Let's define loc met station location
stn = "OakleySth"
stn_lat   = -32.657
stn_lon   = 115.9285

#open file
fname = "wrfout_d03_2018-02-27_00"
f = Nio.open_file(fname, 'r', format='nc')

#Obtain temp 2m dew point temp, wind spd and wind dir
t2 = wrf.getvar(f, "td2",timeidx=wrf.ALL_TIMES)
#t = wrf.getvar(f, "tc",timeidx=wrf.ALL_TIMES)
t = wrf.g_temp.get_tc(f,timeidx=wrf.ALL_TIMES)
#tk = wrf.getvar(f, "tk",timeidx=wrf.ALL_TIMES)
ws_dir10 = wrf.g_uvmet.get_uvmet10_wspd_wdir(f,timeidx=wrf.ALL_TIMES)

#extract ws and win dir respectively
wd_spd = ws_dir10[0,:,:,:]
wd_dir = ws_dir10[1,:,:,:]

#extract information about times
times_dim = wrf.extract_dim(f, 'Time')
print(times_dim)
times = wrf.extract_times(f, timeidx=wrf.ALL_TIMES, squeeze=True,)

#inteporlate temp at 10m and 30m
h10 = [0.010]
h30 = [0.030]
t10 = wrf.vinterp(f, field=t, vert_coord='ght_agl', interp_levels=h10, \
           field_type='tc', timeidx=wrf.ALL_TIMES)
t30 = wrf.vinterp(f, field=t, vert_coord='ght_agl', interp_levels=h30, \
            field_type='tc', timeidx=wrf.ALL_TIMES)

#extract at specific location by finding closest site to WRF grid
x_y = wrf.ll_to_xy(f, stn_lat, stn_lon)
print(x_y)

#subset the climate variables at met stn
t2_sel = t2.sel(west_east=x_y[0],south_north=x_y[1])
t10_sel = t10.sel(west_east=x_y[0],south_north=x_y[1])
t30_sel = t30.sel(west_east=x_y[0],south_north=x_y[1])
wd_spd_sel = wd_spd.sel(west_east=x_y[0],south_north=x_y[1])
wd_dir_sel = wd_dir.sel(west_east=x_y[0],south_north=x_y[1])

#seperate out each variable to write to a table
np_times = wrf.to_np(times)
np_times_ravel = np.ravel(np_times,order='C')

np_t2 = wrf.to_np(t2_sel)
np_t2_ravel = np.ravel(np_t2,order='C')

np_t10 = wrf.to_np(t10_sel)
np_t10_ravel = np.ravel(np_t10,order='C')

np_t30 = wrf.to_np(t30_sel)
np_t30_ravel = np.ravel(np_t30,order='C')

np_wd_spd = wrf.to_np(wd_spd_sel)
np_wd_spd_ravel = np.ravel(np_wd_spd,order='C')

np_wd_dir = wrf.to_np(wd_dir_sel)
np_wd_dir_ravel = np.ravel(np_wd_dir,order='C')

#build an array with all your variables
arr2D = np.array([np_times_ravel,np_t2_ravel,np_t10_ravel,\
                  np_t30_ravel,np_wd_spd_ravel,np_wd_dir_ravel])
print(arr2D)

#settings for headings and tables
fmt_arr2D = "%s"
headers = 'time, temp_2m, temp_10m, temp_30m, wd_sp, wd_dir'

#going to have to write 2 texts files and stitch times together
np.savetxt('time.csv', np.transpose(np_times_ravel), fmt_arr2D, delimiter=',', header='date_time')
#for the climate variables
np.savetxt((stn + 'WRF_T2_T10_WS_WD.csv'), np.transpose(arr2D), fmt_arr2D, \
            delimiter=',', header=headers, comments='')

print("script actually finished thank fuck for that")


#end file
