format ELF64
public main

extrn SetTargetFPS
extrn InitWindow
extrn CloseWindow
extrn WindowShouldClose
extrn BeginDrawing
extrn EndDrawing
extrn DrawRectangle
extrn DrawText
extrn ClearBackground
extrn IsKeyPressed

define KEY_W     87
define KEY_A     65
define KEY_S     83
define KEY_D     68
define KEY_ENTER 257

section '.text' executable

main:
	sub rsp, 8

	call init

	.loop:
	    call checkInput
		call moveSnake
		cmp rax, 1
		je .lose
		call drawScreen

		call WindowShouldClose
		test rax, rax
		jz .loop

	.lose:
		call CloseWindow

		add rsp, 8

		mov rax, 60
		mov edi, 0
		syscall


init:
	sub rsp, 8

	mov rdi, 800
	mov rsi, 600
	mov rdx, title
	call InitWindow

	mov rdi, 60
	call SetTargetFPS

; Open /dev/urandom
	mov rax, 2
	mov rdi, urandom
	mov rsi, 0
	mov rdx, 0
	syscall
	mov [fd], rax

; Read 4 bytes to seed the 32-bit LCG PRNG
	mov rax, 0
	mov rdi, [fd]
	mov rsi, randVal
	mov rdx, 4
	syscall

; Close /dev/urandom
	mov rax, 3
	mov rdi, [fd]
	syscall

	call newFood

	add rsp, 8
	ret

drawScreen:
	sub rsp, 8

	call BeginDrawing

	mov edi, [bgColor]
	call ClearBackground

; ----- Snake Head -----
	mov edi, [headX]
	mov esi, [headY]
	mov edx, [segSize]
	mov ecx, [segSize]
	mov r8d, [headColor]
	call DrawRectangle

; ----- Food -----
	mov edi, [foodX]
	mov esi, [foodY]
	mov edx, [segSize]
	mov ecx, [segSize]
	mov r8d, [foodColor]
	call DrawRectangle

	call EndDrawing

	add rsp, 8
	ret

checkInput:
    sub rsp, 8

    .moveUp:
        mov edi, KEY_W
        call IsKeyPressed
        cmp rax, 1
        jne .moveDown
        cmp dword [headYVel], 1
        je .moveDown
        mov dword [headXVel], 0
        mov dword [headYVel], -1
        jmp .done

    .moveDown:
        mov edi, KEY_S
        call IsKeyPressed
        cmp rax, 1
        jne .moveLeft
        cmp dword [headYVel], -1
        je .moveLeft
        mov dword [headXVel], 0
        mov dword [headYVel], 1
        jmp .done

    .moveLeft:
        mov edi, KEY_A
        call IsKeyPressed
        cmp rax, 1
        jne .moveRight
        cmp dword [headXVel], 1
        je .moveRight
        mov dword [headXVel], -1
        mov dword [headYVel], 0
        jmp .done

    .moveRight:
        mov edi, KEY_D
        call IsKeyPressed
        cmp rax, 1
        jne .done
        cmp dword [headXVel], -1
        je .done
        mov dword [headXVel], 1
        mov dword [headYVel], 0

    .done:
        add rsp, 8
        ret

moveSnake:
	sub rsp, 8

	inc dword [moveTimer]
	mov eax, [moveTimer]
	cmp eax, [moveDelay]
	jb .noMove

	mov dword [moveTimer], 0

	mov edi, [headX]
	mov eax, [headXVel]
	imul eax, [moveAmount]
	add edi, eax
	mov [headX], edi

	mov esi, [headY]
	mov eax, [headYVel]
	imul eax, [moveAmount]
	add esi, eax
	mov [headY], esi

	; Return 1 when any part of the head is outside the window.
	mov eax, [headX]
	cmp eax, 0
	jl .outOfBounds
	add eax, [segSize]
	cmp eax, 800
	jg .outOfBounds

	mov eax, [headY]
	cmp eax, 0
	jl .outOfBounds
	add eax, [segSize]
	cmp eax, 600
	jg .outOfBounds

	.noMove:
	xor eax, eax
	jmp .done

	.outOfBounds:
	mov eax, 1

	call checkFood

	.done:
        add rsp, 8
        ret

newFood:
    sub rsp, 8

    mov eax, [randVal]
    mul dword [randMult]
    add eax, [randInc]
    adc edx, 0
    div dword [randMod]
    mov [randVal], edx

; Choose a grid cell, then convert it to pixel coordinates.  The grid
; spacing matches moveAmount so the snake and food always line up.
    mov ecx, 800
    sub ecx, [segSize]
    mov eax, ecx
    xor edx, edx
    div dword [moveAmount]
    inc eax
    mov ecx, eax
    mov eax, [randVal]
    xor edx, edx
    div ecx
    mov eax, edx
    mul dword [moveAmount]
    mov [foodX], eax

    mov ecx, 600
    sub ecx, [segSize]
    mov eax, ecx
    xor edx, edx
    div dword [moveAmount]
    inc eax
    mov ecx, eax
    mov eax, [randVal]
    xor edx, edx
    div ecx
    mov eax, edx
    mul dword [moveAmount]
    mov [foodY], eax

    add rsp, 8
    ret

checkFood:
    sub rsp, 8



    add rsp, 8
    ret

section '.data' writeable
	title: db "FASM Snake!", 0
	subtitle: db "Press enter to play or esc to exit!", 0
	titleX: dd 400
	titleY: dd 200
	titleSize: dd 32
	titleColor: dd 0xFFFFFFFF

	loseText: db "You Lose!", 0
	retryText: db "Press Enter to Retry", 0

	urandom: db "/dev/urandom"
	fd: dq ?

	bgColor: dd 0xFF882851 ; AA BB GG RR

	headColor: dd 0xFFA7A7A7

	moveAmount: dd 10
	moveDelay: dd 12
	moveTimer: dd 0

	segSize: dd 10

	headX: dd 500
	headY: dd 250

	foodX: dd 100
	foodY: dd 100
	foodColor: dd 0xFF0000FF

    randVal: dd 6767
    randMod: dd 2147483648
	randMult: dd 1103515245
	randInc: dd 12345

	headXVel: dd 1
	headYVel: dd 0


section '.note.GNU-stack'