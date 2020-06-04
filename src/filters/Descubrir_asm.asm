section .rodata

align 16

mirrorMask: times 4 db 0x0C,0x0C,0x0C,0x00
srcMask: times 4 db 0x03,0x03,0x03,0x00

grayMask: times 4 db 0x01,0x00,0x00,0x00
alphaMask: times 4 db 0x00,0x00,0x00,0xFF

grayBroadcastMask: db 0x00,0x00,0x00,0x00,0x04,0x04,0x04,0x04,0x08,0x08,0x08,0x08,0x0C,0x0C,0x0C,0x0C

section .text

global Descubrir_asm
;Aridad: void Descubrir_asm (uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
	;rdi: src
	;rsi: dst
	;edx: width
	;ecx: height

Descubrir_asm:

	push rbp
	mov rbp, rsp

	movdqa xmm2, [mirrorMask]
	movdqa xmm3, [srcMask]
	movdqa xmm4, [grayMask]
	movdqa xmm5, [alphaMask]
	movdqa xmm6, [grayBroadcastMask]

	xor rax, rax
	mov eax, ecx
	mul edx
	shl rdx, 32
	or rax, rdx 	;rax: widht * height

	mov r8, rax
	shl r8, 2		;r8: cantidad total de bytes

	shr rax, 2
	mov rcx, rax	;rcx: cantidad de iteraciones

	mov r9, rdi
	add r9, r8
	sub r9, 16		;puntero para recorrer al reves

.ciclo:
	
	movdqu xmm8, [rdi]	;src
	movdqu xmm9, [r9]	;mirror

	movdqa xmm10, xmm3
	pand xmm8, xmm10				;bits 0 y 1 de cada componente

	movdqu xmm11, xmm9
	pshufd xmm9, xmm11, 00011011b		;pixels al reves

	movdqa xmm10, xmm2
	pand xmm9, xmm10				;bits 2 y 3 de cada componente

	psrlw xmm9, 2					;bits 2 y 3 de cada componente ubicados en 0 y 1

	pxor xmm8, xmm9					; xmm8 = |...|x x x x x x s2 s5|x x x x x x s3 s6|x x x x x x s4 s7|
									; s7s6s5s4s3s2s1s0 es el byte de escala de grises
	pxor xmm0, xmm0

	movdqa xmm10, xmm4

	;bit s7
	movdqu xmm11, xmm10
	pand xmm11, xmm8				;bit s7 en posicion 0
	pslld xmm11, 7
	por xmm0, xmm11					;bit s7 en posicion 7 en cada pixel

	;bit s4
	movdqu xmm11, xmm10
	pslld xmm11, 1					;ubico mascara
	pand xmm11, xmm8				;bit s4 en posicion 1
	pslld xmm11, 3
	por xmm0, xmm11					;bit s4 en poscion 4 en cada pixel

	;bit s6
	movdqu xmm11, xmm10
	pslld xmm11, 8					;ubico mascara
	pand xmm11, xmm8				;bit s6 en posicion 8
	psrld xmm11, 2
	por xmm0, xmm11					;bit s6 en poscion 6 en cada pixel

	;bit s3
	movdqu xmm11, xmm10
	pslld xmm11, 9					;ubico mascara
	pand xmm11, xmm8				;bit s3 en posicion 9
	psrld xmm11, 6
	por xmm0, xmm11					;bit s3 en poscion 3 en cada pixel

	;bit s5
	movdqu xmm11, xmm10
	pslld xmm11, 16					;ubico mascara
	pand xmm11, xmm8				;bit s5 en posicion 16
	psrld xmm11, 11
	por xmm0, xmm11					;bit s5 en poscion 5 en cada pixel

	;bit s2
	movdqu xmm11, xmm10
	pslld xmm11, 17					;ubico mascara
	pand xmm11, xmm8				;bit s2 en posicion 17
	psrld xmm11, 15
	por xmm0, xmm11					;bit s2 en poscion 2 en cada pixel

	;xmm0 = |x|x|x|gris3|x|x|x|gris2|x|x|x|gris1|x|x|x|gris0|

	pshufb xmm0, xmm6

	;xmm0 = |x|gris3|gris3|gris3|x|gris2|gris2|gris2|x|gris1|gris1|gris1|x|gris0|gris0|gris0|

	por xmm0, xmm5

	;xmm0 = |255|gris3|gris3|gris3|255|gris2|gris2|gris2|255|gris1|gris1|gris1|255|gris0|gris0|gris0|

	movdqu [rsi], xmm0
	add rdi, 16
	add rsi, 16
	sub r9, 16
	dec rcx
	test rcx, rcx
	jnz .ciclo

	pop rbp
	ret
