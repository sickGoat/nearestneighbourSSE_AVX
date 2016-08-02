section .data

dataset_addr_nnC	equ		8
row_nnC				equ 	12
column_nnC			equ		16
centro_addr_nnC		equ		20
class_nnC			equ		24
res_addr_nnC		equ		28
align 16
first_swap: dd 1.0 , 1.0 , 1.0 ,1.0
section .bss

cur_dist_nnC	resd	1
cur_min_nnC		resd	1
min_index_nnC	resd	1

section .text
global nnC
extern dist
nnC:
      ; rdi = dataset
      ; rsi = row dataset
      ; rdx = column dataset
      ;	rcx = *target
      ;	xmm0 = class
      ; r8 = *result
	  push       rbp
	  mov        rbp,rsp
	  push		 rbx
	  push		 r12
	  push		 r13
	  push		 r14
	  push		 r15
      ;azzero le variabili bss
      xor	  eax,eax ; eax = iteratore
      mov	  [cur_dist_nnC],eax
      mov	  [cur_min_nnC],eax
      mov	  [min_index_nnC],eax
	  xor	  R10,R10 ; R10 = 0 per valutare il primo swap
loop_nnC:
      ;loop -> controllo prima se sono arrivato alla
	  ;fine della matrice, in caso contrario controllo
	  ;se la classe della riga è uguale a quella passata
	  ;come input in caso contrario passo all'iterazione
	  ;successiva altrimenti lancio dist
	  cmp	  eax,esi ; if eax == row dataset
	  je	  exit_nnC
	  sub	  rdx,1 ;sottraggo per arrivare all'ultima colonna
	  movss	  xmm1,[edi+edx*4] ; xmm1[0] contiene la classe della riga corrente
	  add	  rdx,1 ;ripristino il valore del numero delle colonne
	  ucomiss xmm0,xmm1
	  je	  launch_dist
	  mov	  R11D,edx ; muovo il valore delle colonne in R11D
	  imul	  R11D,4 ; R11D contiene l'offset per skippare alla riga successiva
	  add	  edi,R11D ; edi punta alla riga successiva
	  add	  eax,1
	  jmp	  loop_nnC

launch_dist:
	  ;preparo la chiamata al metodo dist
	  ;dist(target,&dataset[i*column_dataset],column_dataset,&cur_dist)
	  ;rdi contiene gia l'indirizzo del vettore dataset[i*column_dataset]
	  mov	  R12D,esi ; R12D contiene row dataset, per poi eseguire il restore
	  mov	  R14D,ecx ; R14D contiene *target
	  movss	  xmm4,xmm0
	  mov	  rsi,rcx ; rsi = *target
	  mov	  rcx,cur_dist_nnC
	  ;rdx sta bene com'è
	  call	  dist
	  mov	  esi,R12D
	  mov	  ecx,R14D
	  movss	  xmm0,xmm4
	  ;valuto se ancora non ho eseguito nessuno swap
	  cmp	  R10,0
	  je	  swap_nnC
	  movss	  xmm1,[cur_min_nnC]
	  movss	  xmm2,[cur_dist_nnC]
	  ucomiss xmm2,xmm1 ;valuto se cur_dist_nnC < cur_min_nnC
	  jb	  swap_nnC
      mov	  R11D,edx ; muovo il valore delle colonne in R11D
	  imul	  R11D,4 ; R11D contiene l'offset per skippare alla riga successiva
	  add	  edi,R11D ; edi punta alla riga successiva
	  add	  eax,1
	  jmp	  loop_nnC

 swap_nnC:
	  mov	  R10,1 ; il prossimo test fallirà
 	  movss	  xmm1,[cur_dist_nnC]
 	  movss	  [cur_min_nnC],xmm1
 	  mov	  [min_index_nnC],eax
 	  mov	  R11D,edx ; muovo il valore delle colonne in R11D
	  imul	  R11D,4 ; R11D contiene l'offset per skippare alla riga successiva
	  add	  edi,R11D ; edi punta alla riga successiva
	  add	  eax,1
	  jmp	  loop_nnC

 exit_nnC:
	  mov	  rax,[min_index_nnC] ; eax = min_index_nn
	  mov	  [r8],rax ; salvo il valore di ritorno
	  pop     r15
	  pop	  r14
	  pop	  r13
	  pop	  r12
	  pop	  rbx
	  mov	  rsp,rbp
	  pop	  rbp
	  ret
