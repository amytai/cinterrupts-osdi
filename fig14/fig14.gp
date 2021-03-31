fontsiz = 18
smallfontsiz = 16
set terminal postscript eps color enhanced fontsiz;
#set output 'pure-mix.eps'
set output 'fig14.eps'
#infile = 'pure-mix.txt'
infile = 'fig14.txt'
# set datafile separator comma

#-------------------------------------------------------------------------------
# dimensions
#-------------------------------------------------------------------------------

xsiz = .17;  # x size of each subfig
ysiz = .22;  # y size of each subfig
xoff = .04;  # push all subfigs to right by xoff to make room for joint ylabel
yoff = .08;  # push all subfigs upwards by yoff
xnum = 4;    # how many subfigs per row
ynum = 2;    # how many subfigs per column
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
set xrange [0.5:4.5];
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
i=1  ; arYhi[i]=150; arYtic[i]= 50;  arTitle[i]="sync latency\n[{/Symbol m}sec]";
i=1+1; arYhi[i]=600; arYtic[i]=200;  arTitle[i]="async IOPS\n"."[1000s]";
i=i+1; arYhi[i]=600; arYtic[i]=200;  arTitle[i]="async inter.\n"."[1000s/sec]";
i=i+1; arYhi[i]=  9; arYtic[i]=  3;  arTitle[i]="async cycles    \n"."[1000s/IO]";

i=i+1; arYhi[i]= 60; arYtic[i]= 20;
i=i+1; arYhi[i]=600; arYtic[i]=200;
i=i+1; arYhi[i]=600; arYtic[i]=200;
i=i+1; arYhi[i]=  9; arYtic[i]=  3;



#-------------------------------------------------------------------------------
# plot all sub-figs
#-------------------------------------------------------------------------------
do for [l=1:ynum] {
  do for [k=1:xnum] {

    k0   = k + xnum*(l-1);
    i    = k-1;
    j    = ynum-l;
    c0   = 3; # where the metrics begin
    col  = k+c0-1;
    idx  = sprintf("disk%d", l-1);
    xlab = "(" . word(arXlbl, k) . ")";
    ylab = (l==1) ? 'P3700' : 'Optane';

    f(y) = (col==c0+1 || col==c0+2 || col==c0+3) ? y/1000.0 : y;
    yrel(ycur,ybase,bar) = (bar==0) ? "" : sprintf("%.2f", ycur/ybase);

    set origin (xoff + i*xsiz), (yoff + j*ysiz);

    if(l==ynum      ) {set xlabel xlab;        }
    if(l==1         ) {set title arTitle[k]    }
    if(arYhi[k ] > 0) {set yrange [0:arYhi[k0]]} else {set yrange [0:*];  }
    if(arYtic[k0]> 0) {set ytics arYtic[k0];   } else {set ytics autofreq;}
    if(k0==1        ) {set ylabel ylab off 1,0; }
    if(k0==5        ) {set ylabel ylab off 0,0; }
#   if(k==4         ) {set format y "%1.1f"; } else {unset format y; }


    plot \
      infile index idx \
         u 1:(f(column(col))):1 lc variable , \
      '' index idx \
         u 1:( y=f(column(col)), yb=($0==0)? y : yb, y ):( yrel(y,yb,$0) ) \
         w labels rotate left font ",".smallfontsiz offset 0,.2 textcol 'gray30'

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
set key at screen .01, screen 0.01 \
	Left left bottom reverse samplen .5 spacing .8 width .8 maxrow 1
set origin xall,yall; # outside plot area
plot "$data" \
     u 0:1 t 'cint', \
  '' u 0:1 t 'default', \
  '' u 0:1 t 'adaptive', \
  '' u 0:1 t 'ooocint'
