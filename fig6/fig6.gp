#!/usr/local/bin/gnuplot

fontsiz = 18
smallfontsiz = 16
tinyfontsiz = 16
set terminal postscript eps color enhanced fontsiz;
set output 'fig6.eps'
infile = 'fig6.txt'
# set datafile separator comma

#-------------------------------------------------------------------------------
# dimensions
#-------------------------------------------------------------------------------

xsiz = .17;  # x size of each subfig
ysiz = .23;  # y size of each subfig
xoff = .00;  # push all subfigs to right by xoff to make room for joint ylabel
yoff = .15;  # push all subfigs upwards by yoff
xnum = 4;    # how many subfigs per row
ynum = 1;    # how many subfigs per column
toff = .095;  # for top title

xall = xoff + xnum*xsiz;          # x size of the entire multiplot figure
yall = yoff + ynum*ysiz + toff;   # y size of the entire multiplot figure
#print "xall=", xall, " yall=", yall;

set size xall,yall;  # entire fig dimensions
set multiplot;	     # this is what makes this fig a multiplot
set size xsiz,ysiz;  # dimensions of each subfig

#-------------------------------------------------------------------------------
# styles
#-------------------------------------------------------------------------------

set style data linespoints
w=4; p=1.4
set style line 1 lt 3 lw w   ps p pt 1; # adaptive
set style line 2 lt 1 lw w+1 ps p pt 2  # cint

#set style histogram rowstacked
#set boxwidth .75 relative; # relative=fracOfDefault, absolute=unitsAlongXaxis
#set style fill solid .8 border -1; # fill=solid|pattern
#set style data boxes;              # boxs|histograms

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set lmargin 4
set rmargin 1
set tmargin 0.9
set bmargin 1

#-------------------------------------------------------------------------------
# axes etc.
#-------------------------------------------------------------------------------

# set border back;   # place borders below data
unset border;
set grid y; # lc "gray";
set yrange [0:*];
set xrange [3:64];
set logscale x 2
set xtics rotate nomirror out scale 0 font ",".smallfontsiz
set ytics scale 0 nomirror offset .5,0

set title offset 0,.5
unset key

set label 1 'adaptive coalescing threshold' \
  at screen (xoff + xsiz*xnum/2.0), screen 0.1 center


#-------------------------------------------------------------------------------
# arrays for n=1
#-------------------------------------------------------------------------------
arXlbl = "a b c d e f g h i";
array arTitle[xnum];

N = xnum*ynum;
array arYlo[N];
array arYhi[N];
array arYtic[N];
array arCint[N];
do for [i=1:N] { arYlo[i]=0; arYhi[i]=0; arYtic[i]=0; }

# line=1
i=1  ; arYlo[i]=300;  arYhi[i]=  0; arYtic[i]= 50;
i=i+1; arYlo[i]=  0;  arYhi[i]= 45; arYtic[i]= 15;
i=i+1; arYlo[i]=  0;  arYhi[i]=  0; arYtic[i]= 60;
i=i+1; arYlo[i]=  0;  arYhi[i]=  0; arYtic[i]= 30;

i=1  ; arTitle[i] = "total IOPS\n"."[1000s]";
i=i+1; arTitle[i] = "sync IOPS\n"."[1000s]";
i=i+1; arTitle[i] = "sync latency\n[{/Symbol m}sec]";
i=i+1; arTitle[i] = "interrupts\n"."[1000s]";

i=1  ; arCint[i]=341362; # total
i=i+1; arCint[i]= 42887; # sync
i=i+1; arCint[i]=  22.7; # lat
i=i+1; arCint[i]= 42890; # inter

#-------------------------------------------------------------------------------
# plot all sub-figs
#-------------------------------------------------------------------------------
do for [l=1:ynum] {
  do for [k=1:xnum] {

    k0   = k + xnum*(l-1);
    i    = k-1;
    j    = ynum-l;
    col  = k+4;
    idx  = 'idx.adaptive';
    xlab = "(" . word(arXlbl, k) . ")";

    f(y) = (col==5 || col==6 || col==8) ? y/1000.0 : y;
    yrel(ycur,ybase) = \
      (r=ycur/ybase, r>1.5 ? sprintf("%.1f",r) : sprintf("%.2f",r));
    cint(x) = arCint[k];

    set origin (xoff + i*xsiz), (yoff + j*ysiz);
    
    if(l==ynum      ) {set xlabel xlab offset 0,-0.4;  }
    if(l==1         ) {set title arTitle[k]    }
    if(arYhi[k ] > 0) {set yrange [0:arYhi[k0]]} else {set yrange [0:*];  }
    if(arYlo[k ] > 0) {set yrange [arYlo[k0]:] }
    if(arYtic[k0]> 0) {set ytics arYtic[k0];   } else {set ytics autofreq;}

    if(l==1 && k==1) {

	set key at screen 0.13, screen 0.005 \
 	  Left left bottom reverse samplen 1 spacing .8 vertical maxrows 1 \
	  width 9
    }

    plot \
      f(cint(x)) ls 2 t 'cint', \
      infile index idx u 4:(f(column(col))) ls 1 t 'adaptive' , \
      infile index idx u 4:(f(column(col))):(yrel(column(col),cint(0))) not \
         w labels rotate left font ",".tinyfontsiz offset 0,.35 textcol 'gray30'

    unset ylabel; unset xlabel;
    unset label 1;
    unset key;
  }
  unset title;
}

#-------------------------------------------------------------------------------
#legend, using dummy dataset and dummy plot
#-------------------------------------------------------------------------------
# $data << EOD
# 1
# 2
# EOD
# set key at screen xoff+.05, screen 0.01 \
# 	Left left bottom reverse samplen 1 spacing .8 width 2 maxrow 1
# set origin xall,yall; # outside plot area
# plot "$data" \
#      u 0:1 t 'cint', \
#   '' u 0:1 t 'default', \
#   '' u 0:1 t 'adaptive'

