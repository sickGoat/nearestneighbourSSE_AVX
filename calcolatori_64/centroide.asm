;Funzione per
;il calcolo del
;centroide
section .data

align	32
mask: dd 1.0,1.0,1.0,1.0,1.0,1.0,1.0,0.0

section .bss
contatore	resd	1
section .text
global centroide
extern nnC

centroide:
	; rdi = dataset base address
	; rsi = row dataset
	; rdx = column dataset
	; rcx = centro
	; xmm0 = class
	; r8 = return address
	push		rbp
	mov			rbp,rsp
	mov			R10D,edi ; R10D = dataset base address
	mov			R11D,edx ; R11D = column dataset
	imul		R11D,4 ; R11D = offset per skippare alla riga successiva
	sub			edx,1 ; ecx = moltiplicato per 4 restituisce l'offset per saltare all'ultima colonna
	xor			rax,rax ;inizializzo iteratore
	mov			[contatore],eax
	xor 		R12D,R12D ; inizializzo contatore degli elementi
	xorps		xmm2,xmm2
	xorps		xmm1,xmm1
loop_cen:
	cmp			eax,esi ; if iteratore == row dataset
	je			exit_loop_cen
	;scorro fino all'ultima colonna e valuto la classe
	;se la classe è uguale jmp alla somma del vettore
	movss		xmm1,[R10D+edx*4] ; xmm1[0] = class della riga
	ucomiss		xmm1,xmm0
	je			add_cen
	add			R10D,R11D ; R10D ora punta alla riga successiva
	add			eax,1
	jmp			loop_cen

add_cen:
	add			R12D,1 ; aumento il contatore
	xor			R13D,R13D ; iteratore per le colonne
	add			edx,1
loop_add_cen:
	;sommo la riga e jumpo al loop
	sub			edx,R13D ; ecx = column - iteratore
	cmp			edx,8
	je			epure_class_cen
	add			edx,R13D ;edx = (column - iteratore) + column -> iteratore
	vmovaps		ymm1,[R10D+R13D*4];xmm1 contiene la riga corrente
	vaddps		ymm1,[ecx+R13D*4]; sommo al centroide la riga corrente
	vmovaps		[ecx+R13D*4],ymm1 ;salvo la riga sommata
	add			R13D,8
	jmp			loop_add_cen

epure_class_cen:
	add			edx,R13D ; edx = (column - iteratore )+ iteratore
	vmovaps		ymm1,[R10D+R13D*4]
	vmulps		ymm1,ymm1,[mask]
	vaddps		ymm1,ymm1,[ecx+R13D*4]
	vmovaps		[ecx+R13D*4],ymm1
	add			R10D,R11D ; R10D ora punta alla riga successiva
	add			eax,1
	sub			edx,1 ; ripristino il valore delle colonne
	jmp			loop_cen

exit_loop_cen:
	;divido il centroide per il contatore
	xor			 rax,rax ;inizializzo iteratore delle colonne
	VCVTSI2SS	 xmm1,R12D
	vbroadcastss ymm1,xmm1
	add			 edx,1 ; ripristino valore delle colonne
loop_div_cen:

	cmp			eax,edx
	je			exit_cen
	vmovaps		ymm2,[ecx+eax*4]
	vdivps		ymm2,ymm2,ymm1
	vmovaps		[ecx+eax*4],ymm2
	add			eax,8
	jmp			loop_div_cen

exit_cen:
	;lancio la funcione nnClass e ne restituisco il risultato
	; rdi = dataset
    ; rsi = row dataset
    ; rdx = column dataset
    ; rcx = *target
    ; xmm0 = class
    ; r8 = *result
	call		nnC
	mov			rax,[r8]
	mov			rsp,rbp
	pop			rbp
	ret
