#!/usr/bin/gnuplot -p

cint_16="cint_cdf_16.dat"
default_16="default_cdf_16.dat"
adaptive_16="adaptive_cdf_16.dat"

cint_256="cint_cdf_256.dat"
default_256="default_cdf_256.dat"
adaptive_256="adaptive_cdf_256.dat"

set terminal postscript eps color enhanced 16;
set output "fig17.eps"


#-------------------------------------------------------------------------------
# dimensions
#-------------------------------------------------------------------------------

xsiz = .35;  # x size of each subfig
ysiz = .25;   # y size of each subfig
xoff = .06;  # push all subfigs to right by xoff to make room for joint ylabel
yoff = .05;  # push all subfigs upwards by yoff to make room for joint xlabel
xnum = 2;    # how many subfigs per row
ynum = 1;    # how many subfigs per column

xall = xoff + xnum*xsiz;   # x size of the entire multiplot figure
yall = yoff + ynum*ysiz;   # y size of the entire multiplot figure

set size xall,yall;  # entire fig dimensions
set multiplot;       # this is what makes this fig a multiplot
set size xsiz,ysiz;  # dimensions of each subfig

#-------------------------------------------------------------------------------
# define line styles (numbers pertain to "ls" plot argumet)
#-------------------------------------------------------------------------------

set style data linespoints

w=6;   # line width (a regular variable, used below); 1 = default
p=1; # point size (a regular variable, used below); 1 = default

set style line 1 lt 1 pt 2 lw w ps p
set style line 2 lt 2 pt 4 lw w ps p
set style line 3 lt 3 pt 1 lw w ps p
set style line 4 lt 4 pt 3 lw w ps p

#-------------------------------------------------------------------------------
# left/right/top/botom margins -- important to fixate them for multiplot-s,
# otherwise gnuplot optimizes them for each subfig individually, making them
# look different
#-------------------------------------------------------------------------------

set lmargin 2
set rmargin 2
set tmargin 2
set bmargin 2

#-------------------------------------------------------------------------------
# axes, tics, borders, titles
#-------------------------------------------------------------------------------

set xrange [0.100:0.5];
#set xtics rotate rotate
set xtics 0,0.100
set mxtics 5
set yrange [0:1.1];
set mytics 2

set label 1 "latency [ms]" \
  at screen (xoff+xsiz*xnum/2), screen yoff/2 center

#set border 0;       # lose all borders
#set border 1+4;    # lose vertical borders
set border back;   # place borders below data

# set datafile separator comma
set grid y lc "gray";
#set grid x lc "gray";
#set key at screen 0, screen 0.05 samplen 2 left bottom;
set key bottom right font ",13" samplen 1 width -4;

i=0; j=0;
set origin (xoff+i*xsiz),(yoff+j*ysiz);
#set datafile separator ","

set title offset 0,-.5 font ",17" "YCSB-E, scan length=16"
set ylabel font ",16" offset 0.2,0 "CDF"
plot \
  cint_16 using ($1/1000):2 with lines t 'cint' lt 1 lw w, \
  default_16 using ($1/1000):2 with lines t 'default' lt 2 lw w, \
  adaptive_16 using ($1/1000):2 with lines t 'adaptive' lt 3 lw w, \


set xrange [1.8:5.8];
i=1; j=0;
set origin (xoff+i*xsiz),(yoff+j*ysiz);
#set datafile separator ","

unset ylabel
unset label 1
set format y ""
unset key

set xtics 0,.500
set mxtics 5
set title "YCSB-E, scan length=256"
plot \
  cint_256 using ($1/1000):2 with lines t 'cint' lt 1 lw w, \
  default_256 using ($1/1000):2 with lines t 'default' lt 2 lw w, \
  adaptive_256 using ($1/1000):2 with lines t 'adaptive' lt 3 lw w, \
