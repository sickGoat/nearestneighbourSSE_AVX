; La funzione prende due vettori
; e ne restituisce la distanza
; @input : num_column_dataset, a , b
; @output : distanza

section .data
	;dichiarazione maschere
	align 32
	mask3:	dd	1.0,1.0,1.0,1.0,1.0,1.0,1.0,0.0

section .bss

section .text
  global dist
dist:
	; rdi = float* a
	; rsi = float* b
	; rdx = dim
	; rcx = float *result
	push		rbp
	mov			rbp,rsp
	push		rbx
	push		r12
	push		r13
	push		r14
	push		r15
	push		rax
	xor			eax,eax	  ; eax = iteratore
	vxorps		ymm1,ymm1 ; ymm1 mantiene il risultato
	mov			R13D,edx  ; R13D = dim
loop_dist:
	sub			R13D,eax
	cmp			R13D,8
	je 			epure_class
	vmovaps		ymm0,[esi+eax*4] ; muovo i primi otto elementi in
	vsubps		ymm0,[edi+eax*4]
	vmulps		ymm0,ymm0 ; ymm0^2
	vhaddps		ymm0,ymm0
	vhaddps		ymm0,ymm0
	vhaddps		ymm0,ymm0
	vhaddps		ymm0,ymm0
	addss		xmm1,xmm0
	vxorps		ymm0,ymm0
	add			eax,8
	jmp			loop_dist

epure_class:
	vmovaps		ymm0,[esi+eax*4]
	vmovaps		ymm2,[edi+eax*4]
	vmovaps		ymm3,[mask3]
	vmulps		ymm0,ymm3
	vmulps		ymm2,ymm3
	vsubps		ymm0,ymm2
	vmulps		ymm0,ymm0
	vhaddps		ymm0,ymm0
	vhaddps		ymm0,ymm0
	vhaddps		ymm0,ymm0
	vhaddps		ymm0,ymm0
	vaddss		xmm1,xmm1,xmm0

	vsqrtps		ymm1,ymm1
	movss		[rcx],xmm1
	pop			rax
	pop			r15
	pop			r14
	pop			r13
	pop			r12
	pop			rbx
	mov			rsp,rbp
	pop			rbp
	ret
