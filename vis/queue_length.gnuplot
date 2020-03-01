set terminal png size 900,400
set title ""
set ylabel "Queue Length"
set xlabel "Time (milliseconds)"
set xdata time
set timefmt "%s"
set format x "%s"
set key left top
set grid
plot "queue_length.data" using 1:2 with lines title ""
