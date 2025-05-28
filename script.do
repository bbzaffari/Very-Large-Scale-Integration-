
vlib work
vcom fifo_async.vhd
vcom fifo_async_tb.vhd
vsim -wlf /sim/fifo_async_tb -voptargs="+acc" -wlfdeleteonquit fifo_async_tb
add wave sim:/fifo_async_tb/*
add wave sim:/fifo_async_tb/fifo/*
run 3 ms

