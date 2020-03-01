set terminal png size 900,400
set title ""
set ylabel "PIT Response Time (milliseconds)"
set xlabel "Time (milliseconds)"
set xdata time
set timefmt "%s"
set format x "%s"
set key left top
set grid
plot "rt_pit.data" using 1:2 with lines title ""
