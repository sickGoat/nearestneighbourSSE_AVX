; e restituisce l'indice della
; subset che contiene l'indice
; della riga più vicina all'elemento
; puntato da target_index
; funzione: nn(DATASET dataset,int column_dataset,int target,SUBSETID subset,int dim_subset,int *result)
section .data

section .bss
  cur_dist_nn  resd 1
  cur_min_nn   resd 1
  min_index_nn resd 1

section .text
global nn
extern dist
nn:
	; rdi = dataset
	; rsi = column
	; rdx = target index
	; rcx = subset
	; r8 = dim subset
	; r9 = result address
	push		rbp
	mov			rbp,rsp
	push		rbx
	push		r12
	push		r13
	push		r14
	push		r15
	xor			eax,eax ; eax = iteratore
	cmp			R8D,0 ; if dim subset == 0
	je 			exit_nn
	;azzero le variabili in bss
	mov			[cur_dist_nn],eax
	mov			[cur_min_nn],eax
	mov			[min_index_nn],eax
	mov			R10D,edx ; R10D = target index
	imul		R10D,4
	add			R10D,edi ; R10D = &datset[target]
	mov			R11D,edi ; R11D = dataset base address
	mov			R14D,esi ; R14D = column
	mov			R15D,ecx ; R15D = subset base address


loop_nn:
	cmp			eax,r8D
	je			exit_nn
	;eseguo chiamata a dist
	mov			edi,R10D ; edi = &datset[target]

	mov			R12D,eax ; R12D = iteratore
	imul		R12D,4
	add			R12D,R15D ; R12D = &subset[i]
	mov			R12D,[R12D] ; R12D = subset[i]
	imul		R12D,R14D ; R12D = subset[i]*column
	imul		R12D,4
	add			R12D,R11D ; R12D = &dataset[subset[i]*column]
	mov			esi,R12D ; esi =  &dataset[subset[i]*column]
	mov			edx,R14D ; edx = column
	mov			rcx,cur_dist_nn ; rcx = indirizzo variabile di ritorno
	call		dist
	cmp			eax,0
	je			swap_nn
	movss		xmm1,[cur_min_nn]
	movss		xmm2,[cur_dist_nn]
	ucomiss		xmm2,xmm1
	jb			swap_nn
	add			eax,1
	jmp			loop_nn

swap_nn:
	movss		xmm0,[cur_dist_nn]
	movss		[cur_min_nn],xmm0
	mov			[min_index_nn],eax
	add			eax,1
	jmp			loop_nn

exit_nn:
	mov			rax,[min_index_nn] ; eax = cur_min_nn
	mov			[r9],rax ; salvo il valore di ritorno
	pop			r15
	pop			r14
	pop			r13
	pop			r12
	pop			rbx
	mov			rsp,rbp
	pop			rbp
	ret







