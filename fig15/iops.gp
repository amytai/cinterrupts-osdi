set terminal postscript eps color enhanced 20;

#-------------------------------------------------------------------------------
# params that determine how/what to plot:
# set them with the -e flag, which MUST appear before the .gp file, e.g.,
#
#
#-------------------------------------------------------------------------------
do_legend = 1;
do_labels = 1;

#-------------------------------------------------------------------------------
# intput/output file names based on the above params
#-------------------------------------------------------------------------------
infile  = 'iops.dat';
outfile = "fig15-iops.eps";
set output outfile;

#-------------------------------------------------------------------------------
# dimensions
#-------------------------------------------------------------------------------

xsiz = .2;  # x size of each subfig
ysiz = .29;  # y size of each subfig
xoff = .08;  # push all subfigs to right by xoff to make room for joint ylabel
yoff = do_legend ? 0.05 : .10; # push all subfigs upwards by yoff
xnum = 4;    # how many subfigs per row
ynum = 1;    # how many subfigs per column

xall = xoff + xnum*xsiz;   # x size of the entire multiplot figure
yall = yoff + ynum*ysiz;   # y size of the entire multiplot figure
#print "xall=", xall, " yall=", yall;

toff = do_labels ? 0.1 : 0; # make some space for labels on top of bars

set size xall,yall;  # entire fig dimensions
set multiplot;       # this is what makes this fig a multiplot
set size xsiz,ysiz;  # dimensions of each subfig

#-------------------------------------------------------------------------------
# styles
#-------------------------------------------------------------------------------

# set datafile separator comma
set style data linespoints

#---- lines ----
#w=4;           # line width (a regular variable, used below); 1 = default
#p=1;   # point size (a regular variable, used below); 1 = default
#set style line 1 lt 1 pt 2 lw w ps p
#set style line 2 lt 2 pt 4 lw w ps p
#set style line 3 lt 3 pt 1 lw w ps p
#set style line 4 lt 4 pt 3 lw w ps p

#---- bars ----
set boxwidth 0.75 relative; # relative=fracOfDefault, absolute=unitsAlongXaxis
set style fill solid .6 border -1; # fill=solid|pattern
set style data boxes;              # boxs|histograms
#set style histogram rowstacked

# lc overwrites lt and ps/pt are meaningless for bars
#t=1; set style line t lt 1 lw 1 pt t ps 1 lc rgb 'gray80'
#t=2; set style line t lt 1 lw 1 pt t ps 1 lc rgb 'dark-violet'; # (default 1)


#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set lmargin 3
set rmargin 0
set tmargin toff;
set bmargin 2

#-------------------------------------------------------------------------------
# axes, tics, borders, titles, functions
#-------------------------------------------------------------------------------
#set border back;   # place borders below data
unset border
set grid y; # lc "gray";
set yrange [0:*];
set xrange [0.5:4.5];
if(do_legend) {
    unset xtics;
} else {
    set xtics rotate  nomirror out font ",18" offset 0,.2
}
set title offset 0,(-.5 + toff)
unset key
k(x)=(x/1000.0)
ynorm(y,col) = k(y);
yrel(ycur,ybase) = sprintf("%.2f",ycur/ybase)

#-------------------------------------------------------------------------------
# arrays
#-------------------------------------------------------------------------------
array arTitle[xnum];
array arYhi[xnum];
array arYtic[xnum];
array arXlbl[xnum];

do for [i=1:xnum] { arYhi[i]=0; arYtic[i]=0; }

i=1  ; arTitle[i]="" ;        arYhi[i]=  35; arYtic[i]=10; arXlbl[i]="4 threads"
i=i+1  ; arTitle[i]="" ;        arYhi[i]=  35; arYtic[i]=10; arXlbl[i]="8 threads"
i=i+1  ; arTitle[i]="" ;        arYhi[i]=  35; arYtic[i]=10; arXlbl[i]="4 threads"
i=i+1  ; arTitle[i]="" ;        arYhi[i]=  35; arYtic[i]=10; arXlbl[i]="8 threads"

set ylabel "throughput\n degradation [\%]" offset -1,-1

#-------------------------------------------------------------------------------
# plot all sub-figs
#-------------------------------------------------------------------------------
do for [k=1:xnum] {

    i=(k-1); j=0; col=k+2;
    set origin (xoff+i*xsiz),(yoff+j*ysiz);
    set title arTitle[k]

    if(arYhi[k]  > 0 ) { set yrange [arYhi[k]:-20]} else { set yrange [-10:*];   }
    if(arYtic[k] > 0 ) { set ytics arYtic[k];    } else { set ytics autofreq; }
    if( do_legend    ) { set xlabel arXlbl[k]; }

    if (k > 1) {set format y"";unset ylabel;}

    trans(x)=((1-x)*100);

    plot 'iops.dat' u 1:(trans(column(3+3*(k-1)))):1:xtic(2) not lc variable, \
        '' u 1:(trans(column(3+3*(k-1)))):(sprintf("%3d", (column(3+3*(k-1)+2))/1000)) \
         w labels font ",22" offset 0,-0.8, \
         '' u 1:(trans(column(3+3*(k-1)))):(column(3+3*(k-1)+1)*100) \
            w yerrorbars notitle lc "black"

    #if( do_labels ) {
    #   replot 'iops.dat' \
    #     u 1:(3):(sprintf("(%d)", 3)) \
    #     w labels rotate left font ",22" offset 0,.03
    #}
}

#set label 1 "readrandom" font ",24"\
#    at screen (xoff + xsiz), screen ysiz center

#set label 2 "readwhilewriting" font ",24"\
#    at screen (xoff + 3*xsiz), screen ysiz center

#-------------------------------------------------------------------------------
# legend, using dummy dataset and dummy plot
#-------------------------------------------------------------------------------
$data << EOD
1
2
EOD
set key at screen (xoff+xsiz/2), screen 0.01 \
        Left left bottom reverse samplen 1 spacing .8 width -1 maxrow 1
        set origin xall,yall; # outside plot area
        plot "$data" u 0:1 t 'cint', \
            '' u 0:1 t 'default', \
            '' u 0:1 t 'adaptive', \
