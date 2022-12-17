#
# Makefile for MMIF VERSION 3.4.2 2021-06-30
#
# Edit this file to un-comment the section for your compiler.  
# You will also need to edit the line that specifies where to find the 
# NetCDF libraries, which must be compiled by the same compiler.
# The directory "netcdf.4.1.1-mingw" is used to commpile under MS Windows.
# It was compiled using MinGW version 20110802, see http://www.mingw.org, 
# and the script compile_netcdf_mingw.sh.
#
# PGI started linking with the OpenMP library by default in their 11.0 release,
# so that users would be able to use CPU binding even with serial code.  
# Adding "-mp=nonuma -nomp" to FFLAGS fixes "can't find libnuma.so" problems.

# PGI Fortran:
#FC = pgf90
#FFLAGS = -g -fast -Mlfs           # -Mlfs is default on for x86_64
####FFLAGS += -Mbounds               # for bounds checking/debugging
#FFLAGS += -Bstatic_pgi            # to use static PGI libraries
####FFLAGS += -Bstatic               # to use static netCDF libraries
#FFLAGS += -mp=nonuma -nomp        # fix for "can't find libnuma.so"
####FFLAGS += -tp=istanbul            # make code for any x64-compatible processor
####NETCDF = /usr/local/src/netcdf-4.1.1.pgi
#NETCDF = /usr/local/netcdf-4.4.1.1
####HDF5   = /usr/local/src/hdf5-1.8.20.pgi

# GNU gfortran (Windows or Linux, just set NETCDF below correctly)
FC = gfortran
####FFLAGS = -g -Wall
####FFLAGS += -fbounds-check          # for bounds checking/debugging
####FFLAGS += -static                 # to use static libraries
####NETCDF = netcdf-4.1.1-gcc-linux
NETCDF=/apps/hbv2/WRF/Libs/NETCDF

# Intel Fortran:
#FC = ifort
#FFLAGS = -O2 -align dcommons -ipo
#FFLAGS += -static                 # to use static libraries
#NETCDF = /usr/local/apps/netcdf-4.4.1/intel-17.0

# NETCDF values that are the same for all compilers
INCL  = -I$(NETCDF)/include -I$(HDF5)/include
# the "-lnetcdff" version only needed for netcdf-4 and newer
LIBS  = -L$(NETCDF)/lib -lnetcdff -lnetcdf 
####LIBS += -L$(HDF5)/lib -lhdf5_hl -lhdf5 -lm 
####LIBS += -L/usr/lib64 -lz -ldl

PROGRAM = mmif

TODAY   = 2021-12-15
VERSION = 4.0
NEWTAG  = 4.0 2021-12-15
OLDTAG  = 3.4.2rc2 2020-12-15

MODULES = met_fields.f90 functions.f90 module_llxy.f90 wrf_netcdf.f90     \
	parse_control.f90

SOURCES = aggregate.f90 avg_zface.f90 cloud_cover.f90 interpolate.f90     \
	landuse.f90 mmif.f90 output_aercoare.f90 output_aermet.f90        \
	output_calmet.f90 output_onsite.f90 output_scichem.f90            \
	pasquill_gifford.f90 pbl_height.f90 read_mm5.f90 read_wrf.f90     \
	sfc_layer.f90 timesubs.f90 

OBJECTS = $(SOURCES:.f90=.o)
MODOBJS = $(MODULES:.f90=.o)
MODMODS = $(MODULES:.f90=.mod)

$(PROGRAM): $(MODOBJS) $(OBJECTS)
	$(FC) $(FFLAGS) $(MODOBJS) $(OBJECTS) $(LIBS) -o $@

%.o : %.f90 
	$(FC) $(FFLAGS) $(INCL) -c $< -o $@

install: $(PROGRAM)
	cp $(PROGRAM) /usr/local/bin

update_version: 
	sed -i "s|VERSION $(OLDTAG)|VERSION $(NEWTAG)|g" \
		*.f90 README.txt makefile makefile.windows mmif_change_log.txt

distro: 
	mmif --sample > mmif.inp
	unix2dos *.f90 *.sh makefile.windows old_compile.bat README*.txt mmif.inp
	zip -j MMIFv$(VERSION)_$(TODAY).zip \
		mmif.exe mmif mmif.inp *.f90 *.sh makefile \
		makefile.windows old_compile.bat README*.txt \
		MMIFv$(VERSION)_Users_Manual.pdf \
		mmif_change_log.txt test_problems/*/*.inp
	dos2unix *.f90

test_pkg: 
	zip -r MMIFv$(VERSION)_test_problems.zip \
		test_problems -x \*/wrf/\* \*/mm5/\*

test_pkg_mm5+wrf:
	zip -r MMIF_test_problems_mm5+wrf.zip \
		test_problems/wrf \
		test_problems/mm5

clean:
	rm $(MODMODS) $(MODOBJS) $(OBJECTS) $(PROGRAM)
