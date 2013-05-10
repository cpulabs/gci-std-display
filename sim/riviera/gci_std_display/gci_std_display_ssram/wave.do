onerror { resume }
set curr_transcript [transcript]
transcript off

add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/iGCI_CLOCK
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/inRESET
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/iRESET_SYNC
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/b_main_state
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/oSSRAM_CLOCK
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/onSSRAM_ADSC
add wave -height 16 /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/onSSRAM_ADSP
add wave -height 16 /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/onSSRAM_ADV
add wave -height 18 /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/onSSRAM_GW
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/onSSRAM_OE
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/onSSRAM_WE
add wave -height 16 /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/onSSRAM_BE
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/onSSRAM_CE1
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/oSSRAM_CE2
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/onSSRAM_CE3
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/oSSRAM_ADDR
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/ioSSRAM_DATA
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/ioSSRAM_PARITY
add wave -divider {IF Write}
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/iIF_WRITE_REQ
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/iIF_WRITE_ADDR
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/iIF_WRITE_DATA
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/oIF_WRITE_FULL
add wave -divider {Display Out}
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/iDISP_REQ
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/oDISP_DATA_R
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/oDISP_DATA_G
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/oDISP_DATA_B
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/DISPLAY_TIMING/onDISP_VSYNC
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/DISPLAY_TIMING/onDISP_HSYNC
add wave -divider {Memory Write}
add wave -divider {Memory Read}
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/vram_read_start_condition
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/b_read_state
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/b_read_addr
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/b_get_data_valid
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/ioSSRAM_DATA
add wave -logic /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/VRAMREAD_FIFO0/iCLOCK
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/VRAMREAD_FIFO0/iWR_EN
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/VRAMREAD_FIFO0/iWR_DATA
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/VRAMREAD_FIFO0/iWR_EN
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/VRAMREAD_FIFO0/oWR_FULL
add wave /tb_gci_std_display/TARGET/DISPLAY_MODULE/VRAM_CTRL_SSRAM/vramfifo0_data
wv.cursors.add -time 1128139955440fs -name {Default cursor}
wv.cursors.setactive -name {Default cursor}
wv.zoom.range -from 1127910690ps -to 1128566050ps
wv.time.unit.auto.set
transcript $curr_transcript
