quit -sim
.main clear

set PrefMain(saveLines) 100000000000

cd ../sim
cmd /c "if exist work rmdir /S /Q work"
vlib work
vmap work
vmap unisim

vcom -2008 ../source/MyPackage.vhd
vcom -2008 ../source/*.vhd
vcom -2008 ../test/TopModule_tb.vhd

vsim -t 100ps -vopt TopModule_tb -voptargs=+acc

config wave -signalnamewidth 1

add wave -format Logic -radix decimal sim:/TopModule_tb/TopModuleInst/*

run 3 ms
