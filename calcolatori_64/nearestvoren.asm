section .data

section .bss

cur_dist_nV			resd	1
cur_min_nV			resd	1
min_index_nV		resd	1
nearest				resd	1

section .text
extern	dist
extern	nn
global nearestVoren



nearestVoren:
	;rdi = dataset
	;rsi = row dataset
	;rdx = column dataset
	;rcx = target
	;r8 = subset base
	;r9 = dim subset
	 push       rbp
	 mov        rbp,rsp
	 push		rbx
	 push		r12
	 push		r13
	 push		r14
	 push		r15
	 mov		[min_index_nV],esi; inizializzo la variabile min index al numero di righe
	 CVTSI2SS	xmm15,edi ; xmm15[0] = dataset address
	 shufps		xmm15,xmm15,01000101b
	 CVTSI2SS   xmm15,edx ; xmm15 = column dataset
	 shufps		xmm15,xmm15,11100001b
	 CVTSI2SS   xmm15,R8D ; xmm6 = subset base address
	 shufps		xmm15,xmm15,00100111b
	 CVTSI2SS	xmm15,R9D ; xmm15 = dim subset,columns,dataset base address,subset base address
	 vperm2f128 ymm15,ymm15,ymm15, 00000001b ; muovo il contenuto nella parte alta
	 mov		R9D,ecx ; R9D = target index
	 imul		R9D,4
	 add		R8D,R9D ; &subset[target_index]
	 mov		R8D,[R8D] ; R8D = subset[target_index]
	 imul		R8D,edx ; R8D = subset[target_index]*columns
	 imul		R8D,4
	 add		R8D,edi ; R8D = &dataset[subset[target]*columns]
     CVTSI2SS  	xmm15,R8D ; xmm15 = &dataset[subset[target]*columns]
     shufps		xmm15,xmm15,01000101b
	 sub        edx,1 ; column-1
     imul       edx,4 ;offset per puntare all'ultima colonna (classe) (columns-1)*4
	 CVTSI2SS   xmm15,edx
	 shufps		xmm15,xmm15,01100011b
	 ;calcolo della classe della riga bersaglio
	 add		R8D,edx
	 movss		xmm5,[R8D]
	 movss		xmm15,xmm5 ; xmm15[0] = classe riga bersaglio
	 shufps		xmm15,xmm15,00100111b ; xmm15 = 0,offset,dataset[subset[target]*column],target class
	 CVTSI2SS   xmm15,ecx ; xmm15 = target_index,offset,dataset[subset[target]*column],target class
	 xor		eax,eax ; inizializzo iteratore
	 mov		R10D,esi ; salvo il valore delle righe del dataset
	 vperm2f128 ymm15,ymm15,ymm15,00000001b ; switch parte alta con parte basse H = target index... L = dim subset
loop_nV:
	 cmp		eax,R10D ;if iteratore == row dataset
	 je			exit_loop_nV
	 ;rdi contiene gia il dataset base adddress
	 CVTTSS2SI  R8D,xmm15 ; R8D = dim subset

	 shufps		xmm15,xmm15,00100111b ;xmm15 = subset base address,columns,dataset base address,dim subset
	 CVTTSS2SI	ecx,xmm15 ; ecx = subset base address

	 shufps		xmm15,xmm15,11100001b ; xmm15 = column , subset base address,dataset base address,dim subset
	 CVTTSS2SI	esi,xmm15 ; esi = column dataset

	 mov		edx,esi ; edx = column dataset
	 imul		edx,eax ; edx = column dataset * i
	 shufps		xmm15,xmm15,11000110b ; xmm15 = dataset base address,subset base address, columns , dim subset
	 mov		R9D,nearest ; R9D = result address
	 push		rax
	 push		R10 ;provare senza push
	 call		nn
	 pop		R10
	 pop		rax
	 ;ripristino xmm6 alla combinazione di partenza
	 shufps		xmm15,xmm15,01001011b
	 mov		R11D,[nearest]
	 vperm2f128 ymm15,ymm15,ymm15,00000001b ; switch parte alta con parte basse H = xmm6 L = xmm7
	 CVTTSS2SI	R12D,xmm15 ; R11D = target index
	 cmp		R11D,R12D
	 je			compare_class
	 add		eax,1
 	 vperm2f128 ymm15,ymm15,ymm15,00000001b ; switch parte alta con parte basse H = xmm6 L = xmm7
	 jmp		loop_nV

compare_class:
	 ;prendo la classe del target index da xmm7
	 ; e la classe di dataset[i*column] e la comparo
	 shufps		xmm15,xmm15,00011011b ; xmm15 = target_class,dataset[subset[target]*columns],offset,target index
     movss		xmm5,xmm15 ; xmm5[0] = target class
	 vperm2f128 ymm15,ymm15,ymm15,00000001b ; switch parte alta con parte basse H = xmm7 L = xmm6
 	 shufps		xmm15,xmm15,11100001b ; xmm15 = columns,dim subset,dataset base address, subset base address
	 CVTTSS2SI	R11D,xmm15 ; R10D = columns
	 imul		R11D,eax ; R10D = i*columns
	 imul		R11D,4
	 vperm2f128 ymm15,ymm15,ymm15,00000001b ; switch parte alta con parte basse H = xmm6 L = xmm7
	 shufps		xmm15,xmm15,11000110b ; xmm15 = offset,dataset[subset[target]*columns],target class,target index
	 CVTTSS2SI	R12D,xmm15 ; R11D = offset
	 add		R11D,R12D ; R10D = i*columns + offset
	 vperm2f128 ymm15,ymm15,ymm15,00000001b ; switch parte alta con parte basse H = xmm7 L = xmm6
	 shufps		xmm15,xmm15,11000110b ; xmm6 = dataset base address,dim subset,columns,subset base address
	 CVTTSS2SI	ebx,xmm15 ; ebx = dataset base address
	 add		R11D,ebx ; R10D = &dataset[i*column_dataset+column_dataset-1]
	 movss		xmm4,[R11D] ; xmm4 = class riga corrente
	 ucomiss	xmm4,xmm5
	 jne		launch_dist_nV
	 ;restore dei registri
	 shufps		xmm15,xmm15,11001001b ; xmm6 = dim subset,columns,dataset base address,subset base address
	 vperm2f128 ymm15,ymm15,ymm15,00000001b ; switch parte alta con parte basse H = xmm6 L = xmm7
	 shufps	xmm15,xmm15,10010011b ; xmm7 = target index,offset,dataset[subset[target]*columns],target class
	 vperm2f128 ymm15,ymm15,ymm15,00000001b ; switch parte alta con parte basse H = xmm7 L = xmm6
	 add		eax,1
	 jmp		loop_nV

launch_dist_nV:
    shufps		xmm15,xmm15,11000110b ; xmm15 = columns,dim subset,dataset base address,subset base address
	CVTTSS2SI	edx,xmm15; edx = columns
	vperm2f128  ymm15,ymm15,ymm15,00000001b ; switch parte alta con parte basse H = xmm6 L = xmm7
	CVTTSS2SI   ebx,xmm15 ; ebx = offset
	sub			R11D,ebx ; R10D = &dataset[i*column_dataset]
	mov			edi,R11D ; edi = float* a
	shufps		xmm15,xmm15,10001101b ; xmm7 = dataset[subset[target]*columns],target index,offset,target class
	CVTTSS2SI	esi,xmm15 ; esi = float *b
	mov			rcx,cur_dist_nV
	push		rax
	push		R10
	vmovaps		ymm0,[edi]
	call		dist
	pop			R10
	pop			rax
	movss		xmm0,[cur_min_nV]
	movss		xmm1,[cur_dist_nV]
	ucomiss	    xmm1,xmm0
	jbe			swap_nV
	;restore dei registri
	shufps		xmm15,xmm15,11001001b ; xmm7 = target index,offset,dataset[subset[target]*columns],target class
	vperm2f128  ymm15,ymm15,ymm15,00000001b ; switch parte alta con parte basse H = xmm7 L = xmm6
	shufps		xmm15,xmm15,11100001b ; xmm6 = dim subset,columns,dataset base address,subset base addre
	add			eax,1
	jmp			loop_nV

swap_nV:
	movss	 	xmm0,[cur_dist_nV]
	movss	  	[cur_min_nV],xmm0
	mov	      	[min_index_nV],eax
	shufps  	xmm15,xmm15,11100001b ; xmm6 = dim subset,columns,dataset base address,subset base addre
	vperm2f128  ymm15,ymm15,ymm15,00000001b ; switch parte alta con parte basse H = xmm6 L = xmm7
	shufps  	xmm15,xmm15,11001001b ; xmm7 = target index,offset,dataset[subset[target]*columns],target class
	vperm2f128  ymm15,ymm15,ymm15,00000001b ; switch parte alta con parte basse H = xmm7 L = xmm6
	add	  		eax,1
	jmp			loop_nV

exit_loop_nV:
    ;mov	  		rax,[rbp+result_address_nV]
    ;mov	        rbx,[min_index_nV]
	;mov	        [rax],rbx
	mov			rax,150
	pop			r15
	pop			r14
	pop			r13
	pop			r12
	pop			rbx
	mov			rsp,rbp
	pop			rbp
	ret
