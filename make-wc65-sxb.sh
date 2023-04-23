CC65_PATH=/c/code_projects/65x_C/6502/CC65/bin
RETRO_TOOL_PATH=/c/code_projects/RetroFileTool/Bin

if [ ! -d tmp ]; then
	mkdir tmp
fi

for i in w65c_sxb; do

echo $i
$CC65_PATH/ca65 -D $i msbasic.s -o tmp/$i.o

# Terminate the build upon error.
if [ $? -ne 0 ]; then
	exit $?
fi

$CC65_PATH/ld65 -vm -m tmp/$i.map -C $i.cfg tmp/$i.o -o tmp/$i.bin -Ln tmp/$i.lbl

# Terminate the build upon error.
if [ $? -ne 0 ]; then
	exit $?
fi

# Invoke RetroFileTool to combine the BASIC image and the reset vector into a single WDC-style binary file.
$RETRO_TOOL_PATH/RetroFileTool.exe -ifb tmp/$i.bin,A=0x200 -ifb tmp/$i.bin-RSTVec.bin,A=0xFFFC -ofw tmp/$i.wdc.bin

# Terminate the build upon error.
if [ $? -ne 0 ]; then
	exit $?
fi

done

