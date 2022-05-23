if [ ! -d tmp ]; then
	mkdir tmp
fi

for i in w65c_sxb; do

echo $i
ca65 -D $i msbasic.s -o tmp/$i.o

# Terminate the build upon error.
if [ $? -ne 0 ]; then
	exit $?
fi

ld65 -vm -m $i.map -C $i.cfg tmp/$i.o -o tmp/$i.bin -Ln tmp/$i.lbl

# Terminate the build upon error.
if [ $? -ne 0 ]; then
	exit $?
fi

/c/code_projects/RetroFileTool/Bin/RetroFileTool.exe -ifb tmp/$i.bin,A=0x200 -ifb tmp/$i.bin-RSTVec.bin,A=0xFFFC -ofw tmp/$i.wdc.bin

# Terminate the build upon error.
if [ $? -ne 0 ]; then
	exit $?
fi

done

