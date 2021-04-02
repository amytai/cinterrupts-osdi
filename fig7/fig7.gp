fontsiz = 18
smallfontsiz = 13
set terminal postscript eps color enhanced fontsiz;
set output 'fig7.eps'
infile = 'fig7.txt'
# set datafile separator comma

#-------------------------------------------------------------------------------
# dimensions
#-------------------------------------------------------------------------------

xsiz = .17;  # x size of each subfig
ysiz = .22;  # y size of each subfig
xoff = .04;  # push all subfigs to right by xoff to make room for joint ylabel
yoff = .08;  # push all subfigs upwards by yoff
xnum = 4;    # how many subfigs per row
ynum = 3;    # how many subfigs per column
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

#set style data linespoints
#set style histogram rowstacked

set boxwidth .75 relative; # relative=fracOfDefault, absolute=unitsAlongXaxis
set style fill solid .8 border -1; # fill=solid|pattern
set style data boxes;              # boxs|histograms

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set lmargin 4
set rmargin 1
set tmargin 1
set bmargin 1

#-------------------------------------------------------------------------------
# axes etc.
#-------------------------------------------------------------------------------

# set border back;   # place borders below data
unset border;
set grid y; # lc "gray";
set yrange [0:*];
set xrange [0.5:3.5];
unset xtics;
set ytics scale 0 nomirror offset .5,0

set title offset 0,.5
unset key

#-------------------------------------------------------------------------------
# arrays for n=1
#-------------------------------------------------------------------------------
arXlbl = "a b c d e f g h i";
array arTitle[xnum];

N = xnum*ynum;
array arYhi[N];
array arYtic[N];
do for [i=1:N] { arYhi[i]=0; arYtic[i]=0; }

# line=1
i=1  ; arYhi[i]=300; arYtic[i]=100;  arTitle[i]="IOPS\n"."[1000s]" ;
i=i+1; arYhi[i]= 45; arYtic[i]= 15;  arTitle[i]="latency\n[{/Symbol m}sec]";
i=i+1; arYhi[i]= 110; arYtic[i]= 25;  arTitle[i]="CPU util\n[%]";
i=i+1; arYhi[i]=300; arYtic[i]=100;  arTitle[i]="interrupts\n[1000s]";

# line=2
i=i+1; arYhi[i]=300; arYtic[i]=100; 	# iops
i=i+1; arYhi[i]= 45; arYtic[i]= 15; 	# latency
i=i+1; arYhi[i]= 110; arYtic[i]= 25; 	# idle cpu
i=i+1; arYhi[i]=300; arYtic[i]=100; 	# interrupts

# line=2
i=i+1; arYhi[i]=300; arYtic[i]=100; 	# iops
i=i+1; arYhi[i]= 90; arYtic[i]= 30; 	# latency
i=i+1; arYhi[i]= 110; arYtic[i]= 25; 	# idle cpu
i=i+1; arYhi[i]=300; arYtic[i]=100; 	# interrupts

#-------------------------------------------------------------------------------
# plot all sub-figs
#-------------------------------------------------------------------------------
do for [l=1:ynum] {
  do for [k=1:xnum] {

    k0   = k + xnum*(l-1);
    i    = k-1;
    j    = ynum-l;
    col  = k+4;
    idx  = sprintf("idx.%d", l);
    xlab = "(" . word(arXlbl, k) . ")";
    ylab = sprintf("%d %s", 2**(l-1), (l==1 ? "proc" : "procs"));
    
    f(y) = (col==5 || col==8) \
      ? y/1000.0 \
      : (col==7 && y<2) ? 0 : y;
    yrel(ycur,ybase,bar) = (bar==0||ybase<2) \
      ? "" \
      : sprintf("%.2f", ycur/ybase); # sprintf("%+.0f%%", 100*ycur/ybase-100)
    
    set origin (xoff + i*xsiz), (yoff + j*ysiz);
    
    if(l==ynum      ) {set xlabel xlab;        }
    if(k==1         ) {set ylabel ylab offset 1,0 }
    if(l==1         ) {set title arTitle[k]    }
    if(arYhi[k ] > 0) {set yrange [0:arYhi[k0]]} else {set yrange [0:*];  }
    if(arYtic[k0]> 0) {set ytics arYtic[k0];   } else {set ytics autofreq;}

    plot \
      infile index idx \
         u 1:(f(column(col))):1 lc variable , \
      '' index idx \
         u 1:( y=f(column(col)), yb=($0==0)? y : yb, y ):( yrel(y,yb,$0) ) \
         w labels rotate left font ",16" offset 0,.2 textcol 'gray30'

    unset ylabel; unset xlabel;
  }
  unset title;
}

#-------------------------------------------------------------------------------
#legend, using dummy dataset and dummy plot
#-------------------------------------------------------------------------------
$data << EOD
1
2
EOD
set key at screen xoff+.05, screen 0.01 \
	Left left bottom reverse samplen 1 spacing .8 width 2 maxrow 1
set origin xall,yall; # outside plot area
plot "$data" \
     u 0:1 t 'cint', \
  '' u 0:1 t 'default', \
  '' u 0:1 t 'adaptive'
# plot "$data" \
#      u 0:1 t 'default', \
#   '' u 0:1 t 'adaptive', \
#   '' u 0:1 t 'cint'

