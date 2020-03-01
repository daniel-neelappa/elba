set terminal png size 900,400
set ylabel "# Requests"
set xlabel "Time (seconds)"
set xdata time
set timefmt "%s"
set format x "%s"
set key left top
set grid
plot "requests_per_sec.data" using 1:2 with lines title ""
