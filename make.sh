# 1.0
echo cbmbasic1
ca65 -D CBM -D CBM1 -D CBM_KBD -D CBM_KBD_APPLE -D CONFIG_CBM1_PATCHES -D CBM1_APPLE -D CBM_APPLE msbasic.s -o tmp/cbmbasic1.o &&
ld65 -C cbmbasic1.cfg tmp/cbmbasic1.o -o tmp/cbmbasic1-new.bin && 
xxd -g 1 orig/cbmbasic1.bin > tmp/cbmbasic1.bin.txt
xxd -g 1 tmp/cbmbasic1-new.bin > tmp/cbmbasic1-new.bin.txt
diff -u tmp/cbmbasic1.bin.txt tmp/cbmbasic1-new.bin.txt | head

# 1.0 ?
echo kbdbasic
ca65 -D KBD -D OSI_KBD -D CBM_KBD -D CBM_KBD_APPLE -D CBM2_KBD -D KIM_KBD -D CONFIG_11 -D CONFIG_11_NOAPPLE -D CBM2_KBD_APPLE -D KIM_KBD_APPLE -D OSI_KBD_APPLE msbasic.s -o tmp/kbdbasic.o &&
ld65 -C kbdbasic.cfg tmp/kbdbasic.o -o tmp/kbdbasic-new.bin && 
xxd -g 1 orig/kbdbasic.bin > tmp/kbdbasic.bin.txt
xxd -g 1 tmp/kbdbasic-new.bin > tmp/kbdbasic-new.bin.txt
diff -u tmp/kbdbasic.bin.txt tmp/kbdbasic-new.bin.txt | head

# 1.0 rev 3.2
echo osi
ca65 -D OSI -D OSI_KBD -D OSI_KBD_APPLE msbasic.s -o tmp/osi.o &&
ld65 -C osi.cfg tmp/osi.o -o tmp/osi-new.bin
xxd -g 1 orig/osi.bin > tmp/osi.bin.txt
xxd -g 1 tmp/osi-new.bin > tmp/osi-new.bin.txt
diff -u tmp/osi.bin.txt tmp/osi-new.bin.txt | head

# 1.1
echo kb9
ca65 -D KIM -D KIM_KBD -D CONFIG_11 -D CONFIG_11_NOAPPLE -D CBM2_KIM -D KIM_KBD_APPLE -D CBM2_KIM_APPLE -D KIM_APPLE msbasic.s -o tmp/kb9.o &&
ld65 -C kb9.cfg tmp/kb9.o -o tmp/kb9-new.bin &&
xxd -g 1 orig/kb9.bin > tmp/kb9.bin.txt
xxd -g 1 tmp/kb9-new.bin > tmp/kb9-new.bin.txt
diff -u tmp/kb9.bin.txt tmp/kb9-new.bin.txt | head

# 2
echo cbmbasic2
ca65 -D CBM -D CBM2 -D CONFIG_11 -D CONFIG_11_NOAPPLE -D CBM_KBD -D CBM_KBD_APPLE -D CBM2_KBD_APPLE -D CBM2_KBD -D CBM2_KIM -D CBM2_APPLE -D CBM2_KIM_APPLE -D CBM_APPLE msbasic.s -o tmp/cbmbasic2.o &&
ld65 -C cbmbasic1.cfg tmp/cbmbasic2.o -o tmp/cbmbasic2-new.bin && 
xxd -g 1 orig/cbmbasic2.bin > tmp/cbmbasic2.bin.txt
xxd -g 1 tmp/cbmbasic2-new.bin > tmp/cbmbasic2-new.bin.txt
diff -u tmp/cbmbasic2.bin.txt tmp/cbmbasic2-new.bin.txt | head

# 1.1
echo applesoft
ca65 -D APPLE -D CONFIG_11 -D CBM_KBD_APPLE -D CBM2_APPLE -D CBM2_KBD_APPLE -D KIM_KBD_APPLE -D CBM2_KIM_APPLE -D CBM1_APPLE -D CBM_APPLE -D KIM_APPLE -D OSI_KBD_APPLE msbasic.s -o tmp/applesoft.o &&
ld65 -C applesoft.cfg tmp/applesoft.o -o tmp/applesoft-new.bin && 
xxd -g 1 orig/applesoft.bin > tmp/applesoft.bin.txt
xxd -g 1 tmp/applesoft-new.bin > tmp/applesoft-new.bin.txt
diff -u tmp/applesoft.bin.txt tmp/applesoft-new.bin.txt | head
#da65 --info applesoft-temp.txt 
