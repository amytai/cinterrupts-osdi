#!/usr/bin/gnuplot -p

fontsiz=15;
smallfontsiz=13;
set terminal postscript eps color enhanced fontsiz;

#-------------------------------------------------------------------------------
# intput/output file names based on the above params
#-------------------------------------------------------------------------------
infile  = 'gp.dat';
outfile = 'fig16.eps';
set output outfile;

#-------------------------------------------------------------------------------
# dimensions
#-------------------------------------------------------------------------------

xsiz = .29;  # x size of each subfig
ysiz = .28;  # y size of each subfig
xoff = .08;  # push all subfigs to right by xoff to make room for joint ylabel
yoff = .08;  # push all subfigs upwards by yoff
xnum = 2;    # how many subfigs per row
ynum = 3;    # how many subfigs per column
toff = .00;  # for top title

xall = xoff + xnum*xsiz;          # x size of the entire multiplot figure
yall = yoff + ynum*ysiz + toff;   # y size of the entire multiplot figure
print "xall=", xall, " yall=", yall;

set size xall,yall;  # entire fig dimensions
set multiplot;       # this is what makes this fig a multiplot
set size xsiz,ysiz;  # dimensions of each subfig

#-------------------------------------------------------------------------------
# styles
#-------------------------------------------------------------------------------

# set datafile separator comma
set style data linespoints

#---- lines ----
w=6;    # line width (a regular variable, used below); 1 = default
p=1.5;  # point size (a regular variable, used below); 1 = default
set style line 1 lt 1 pt 2 lw w ps p; # cint
set style line 2 lt 2 pt 4 lw w ps p; # default
set style line 3 lt 3 pt 1 lw w ps p; # adaptive
set style line 4 lt 4 pt 3 lw w ps p; # ooocint

#---- bars ----
#set boxwidth 0.75 relative; # relative=fracOfDefault, absolute=unitsAlongXaxis
#set style fill solid .6 border -1; # fill=solid|pattern
#set style data boxes;              # boxs|histograms
#set style histogram rowstacked

# lc overwrites lt and ps/pt are meaningless for bars
#t=1; set style line t lt 1 lw 1 pt t ps 1 lc rgb 'gray80'
#t=2; set style line t lt 1 lw 1 pt t ps 1 lc rgb 'dark-violet'; # (default 1)


#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set lmargin 2
set rmargin 1
set tmargin 1.5
set bmargin 1

#-------------------------------------------------------------------------------
# axes, tics, borders, titles, functions
#-------------------------------------------------------------------------------
set border back;   # place borders below data
#unset border
set grid y; # lc "gray";
set yrange [0.97:1.16];
set xrange [.5:5.5];
#unset xtics;
set title offset 0,(-.5)
unset key

set label 1 'YCSB workload' at screen (xoff+(xall-xoff)/2), screen 0.02 center

#-------------------------------------------------------------------------------
# arrays
#-------------------------------------------------------------------------------
arXlbl = "a b c d e f g h i j k l";
array arTitle[xnum];
array arLegend[xnum];

# titles
i=1;   arTitle[i] = "a. cint vs. default";
i=i+1; arTitle[i] = "b. cint vs. adaptive";

# legend
i=1;   arLegend[i] = "default";
i=i+1; arLegend[i] = "adaptive";

N = xnum*ynum;
array arYhi[N];
array arYtic[N];
do for [i=1:N] { arYhi[i]=0; arYtic[i]=0; }

# line=1
i=1  ; arYhi[i]=  0; arYtic[i]=  0;
i=i+1; arYhi[i]=  0; arYtic[i]=  0;

# line=2
i=i+1; arYhi[i]=  0; arYtic[i]=  0;
i=i+1; arYhi[i]=  0; arYtic[i]=  0;

# line=3
i=i+1; arYhi[i]=  0; arYtic[i]=  0;
i=i+1; arYhi[i]=  0; arYtic[i]=  0;

set xtics scale 0
#-------------------------------------------------------------------------------
# plot all sub-figs
#-------------------------------------------------------------------------------
do for [l=1:ynum] {
  do for [k=1:xnum] {

    k0   = k + xnum*(l-1); # array index, begins in 1, flattened 2d
    i    = k-1;
    j    = ynum-l;
    c0   = 3; # where the metrics begin
    col  = k + c0;
    error = col + 3;

    if (l ==2) {idx = "idx.avg"; ylab="normalized\n avg latency"; set yrange [0.95:1.08];}
    if (l ==3) {idx = "idx.p99"; ylab="normalized\n p99 latency"; set yrange [0.97:1.12];}
    if (l ==1) {idx = "idx.iops"; ylab='normalized IOPS'; set yrange [0.82:1.04];}
    # xlab = "(" . word(arXlbl, k) . ")";
    lgnd = arLegend[k];

    set origin (xoff + i*xsiz), (yoff + j*ysiz);

    if(l==1         )  {set title arTitle[k];
                        set key bottom left reverse Left samplen 2 width -1 }
    #if(arYhi[k ] > 0) {set yrange [0:arYhi[k0]]} else {set yrange [0:*];  }
    #if(arYtic[k0]> 0) {set ytics arYtic[k0];   } else {set ytics autofreq;}

    if(k==1         )  {set ylabel ylab off -0.5,0;
                        set ytics 0.96, 0.02, 1.08 format "%.2f" }
    else               {set ytics format "" }
    if (l==1 && k==1) {set ytics 0.7,0.05,1 format "%.2f" }
    if (l==3 && k==1) {set ytics 1,0.03,1.12 format "%.2f" }

    lbl(y) = l==1 ? sprintf("%d",y/1000) : sprintf("%.2f",y/1000.0);
    rel(y,yb) = y/yb;

    lbloffset_others=1
    lbloffset_cint= -.8

    if (l==1) {lbloffset_others=-.8; lbloffset_cint=0.8;}

    plot infile \
        index idx u 1:(rel(column(col),column(c0))):xtic(2) t lgnd ls (k+1), \
     '' index idx u 1:(rel(column(col),column(c0))):(rel(column(error), column(c0))) \
        w yerrorlines notitle ls (k+1), \
     '' index idx u 1:(rel(column(col),column(c0))):(lbl(column(col))) \
        w labels off 0,lbloffset_others font ",".smallfontsiz textcolor 'gray30' not ,\
        \
     '' index idx u 1:(rel(column(c0) ,column(c0))):xtic(2) t 'cint' ls 1, \
     '' index idx u 1:(rel(column(c0),column(c0))):(rel(column(3+c0), column(c0))) \
        w yerrorlines notitle ls 1, \
     '' index idx u 1:(rel(column(c0),column(c0))):(lbl(column(c0))) \
        w labels off 0,lbloffset_cint font ",".smallfontsiz textcolor 'gray30' not, \

    unset ylabel; unset xlabel;
    unset key;
    unset label 1;
  }
  unset title;
}
