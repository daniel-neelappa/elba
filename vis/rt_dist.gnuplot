set terminal png size 900,400
set title ""
set ylabel "# Requests"
set xlabel "Response Time (milliseconds)"
set xdata time
set timefmt "%s"
set format x "%s"
set key left top
set grid
set xrange [-30:3000]
set logscale y 10
set boxwidth 50
set style fill solid
plot "rt_dist.data" using 1:2 with boxes title ""
