onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /PayloadBuffer_tb/clock
add wave -noupdate /PayloadBuffer_tb/reset
add wave -noupdate /PayloadBuffer_tb/enable
add wave -noupdate /PayloadBuffer_tb/readWrite
add wave -noupdate -radix unsigned /PayloadBuffer_tb/writeAddress
add wave -noupdate -radix unsigned /PayloadBuffer_tb/dummyAddress
add wave -noupdate /PayloadBuffer_tb/rdBus/isFirst
add wave -noupdate -radix decimal /PayloadBuffer_tb/rdBus/address
add wave -noupdate /PayloadBuffer_tb/rdBus/byteCount
add wave -noupdate -radix unsigned /PayloadBuffer_tb/rdBus/data
add wave -noupdate /PayloadBuffer_tb/rdBus/isLast
add wave -noupdate /PayloadBuffer_tb/rdBus/isDestructive
add wave -noupdate /PayloadBuffer_tb/wrBus/isLast
add wave -noupdate -radix unsigned /PayloadBuffer_tb/wrBus/data
add wave -noupdate -radix unsigned /PayloadBuffer_tb/wrBus/ttl
add wave -noupdate /PayloadBuffer_tb/wrBus/byteCount
add wave -noupdate -radix unsigned /PayloadBuffer_tb/wrBus/address
add wave -noupdate -childformat {{/PayloadBuffer_tb/pb/memRdData.nextPtr -radix decimal}} -subitemconfig {/PayloadBuffer_tb/pb/memRdData.nextPtr {-height 21 -radix decimal}} /PayloadBuffer_tb/pb/memRdData
add wave -noupdate -radix decimal /PayloadBuffer_tb/pb/freePtr
add wave -noupdate -radix unsigned /PayloadBuffer_tb/pb/memRdAddress
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {104524 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 279
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {176128 ps}
