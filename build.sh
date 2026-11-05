fasm main.asm
gcc -o snake main.o -L./raylib/src/ -lraylib -lm -lX11 -lc -no-pie
rm main.o
./snake
