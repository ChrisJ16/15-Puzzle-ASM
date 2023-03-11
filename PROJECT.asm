.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Perspico",0
area_width EQU 640
area_height EQU 480
area DD 0

counter DD 0 ; numara evenimentele de tip timer
counterOK DD 0
end_game DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20

chenar_x EQU 100
chenar_y EQU 50
cell_size EQU 100

matriceNum DD 16 DUP(0)
format_int DB "%d ", 0
format_string DB "%s ", 0
format_new_line DB 13,10,0
mesaj_victorie DB "victorie!",13,10,0

numar1 DD 0
numar2 DD 0

include digits.inc
include letters.inc

; button_x EQU 500 exemplu de cod
; button_y EQU 150
; button_size EQU 80

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

linie_orizontala macro x, y, len, colour ;procedura pentru a desena o linie orizontala
local _loop
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax,2
	add eax, area
	
	mov ecx, len
	
	_loop:
	mov dword ptr[eax], colour
	add eax, 4
	loop _loop

endm

linie_verticala macro x, y, len, colour ;procesura pentru a desnea o linie verticala
local _loop
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax,2
	add eax, area
	
	mov ecx, len
	
	_loop:
	mov dword ptr[eax], colour
	add eax, area_width * 4
	loop _loop
endm

draw_chenar macro x, y, len, clr ; o celula va fi de 80 pe 80, atfel o linie orizontala pt chenar va fi: 80 * 3 = 240
	; avem nevoie de 5 linii orizontale
	linie_orizontala x, y, len*4, clr
	linie_orizontala x, y + len, len*4, clr
	linie_orizontala x, y + len * 2, len*4, clr
	linie_orizontala x, y + len * 3, len*4, clr
	linie_orizontala x, y + len * 4, len*4, clr
	
	; avem nevoie de 5 linii verticale
	
	linie_verticala x, y, len*4, clr
	linie_verticala x + len, y, len*4, clr
	linie_verticala x + len * 2, y, len*4, clr
	linie_verticala x + len * 3, y, len*4, clr
	linie_verticala x + len * 4, y, len*4, clr
endm

;make_text_macro macro symbol, drawArea, x, y
; chenar incepe in x: 100, y:50
; o cifra este de 10 x 16

insert_mat macro element, pozX, pozY, len
local _2digit, cont
	mov eax, element
	cmp eax, 16
	je cont
	cmp eax, 10
	jae _2digit
	add eax, '0'
	make_text_macro eax,area, (pozX + len/2 - 5), (pozY + len/2 - 8)
	jmp cont
	_2digit:
	mov edx,0
	mov ecx,10
	div ecx
	add eax, '0'
	make_text_macro eax,area, (pozX + len/2 - 5), (pozY + len/2 - 8)
	add edx, '0'
	make_text_macro edx,area, (pozX + len/2 + 5), (pozY + len/2 - 8)
	cont:
endm
 
init_mat macro matrice, len, pozX, pozY
	; mov eax, matriceNum[0]  ; -> asa convertim elemente din matrice pt a fi afisate
	; add eax, '0'
	
	;primul rand
	insert_mat matriceNum[0], pozX, pozY, len
	insert_mat matriceNum[4], pozX + 100, pozY, len
	insert_mat matriceNum[8], pozX + 200, pozY, len
	insert_mat matriceNum[12], pozX + 300, pozY, len
	;al doilea rand
	insert_mat matriceNum[16], pozX, pozY + 100, len
	insert_mat matriceNum[20], pozX + 100, pozY + 100, len
	insert_mat matriceNum[24], pozX + 200, pozY + 100, len
	insert_mat matriceNum[28], pozX + 300, pozY + 100, len
	;al treilea rand
	insert_mat matriceNum[32], pozX, pozY + 200, len
	insert_mat matriceNum[36], pozX + 100, pozY + 200, len
	insert_mat matriceNum[40], pozX + 200, pozY + 200, len
	insert_mat matriceNum[44], pozX + 300, pozY + 200, len
	;al patrulea rand
	insert_mat matriceNum[48], pozX, pozY + 300, len
	insert_mat matriceNum[52], pozX + 100, pozY + 300, len
	insert_mat matriceNum[56], pozX + 200, pozY + 300, len
	insert_mat matriceNum[60], pozX + 300, pozY + 300, len
endm

where_click macro pozX, pozY, coordX, coordY, numar
local _cont, button_fail
	mov ecx, coordX
	mov ebx, coordY
	
	mov eax,  pozX
	cmp eax, ecx
	jl button_fail
	add ecx, cell_size
	cmp eax, ecx
	jg button_fail
	mov eax, pozY
	cmp eax, ebx
	jle button_fail
	add ebx, cell_size
	cmp eax, ebx
	jg button_fail
	mov edx, numar
	; add edx, '0'
	; make_text_macro edx, area, 40, 40
	push edx
	mov numar1, edx
	; make_text_macro ' ', area, 35, 40
	; make_text_macro ' ', area, 45, 40
	; text_test numar1, 40, 40
	pop edx 
	
	push edx
	; make_text_macro ' ', area, 35, 100
	; make_text_macro ' ', area, 45, 100
	; text_test numar2, 40, 100
	pop edx
	; mov numar2, edx
	jmp _cont

	button_fail:
	make_text_macro ' ', area, 35, 40
	make_text_macro ' ', area, 45, 40
	
	_cont:
	
endm

text_test macro element, pozX, pozY
local _2digit, cont
	mov eax, element
	cmp eax, 10
	jae _2digit
	add eax, '0'
	make_text_macro eax,area, (pozX ), (pozY )
	jmp cont
	_2digit:
	mov edx,0
	mov ecx,10
	div ecx
	add eax, '0'
	make_text_macro eax,area, (pozX - 5), (pozY )
	add edx, '0'
	make_text_macro edx,area, (pozX  + 5), (pozY)
	cont:
endm

verif_click macro pozX, pozY 
local _cont,_end,_gasire_poz_16,end_gasire_poz_16
	mov edx, 0
	
	cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x, chenar_y, matriceNum[0]
	cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x + 100, chenar_y, matriceNum[4]
    cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x + 200, chenar_y, matriceNum[8]
	cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x + 300, chenar_y, matriceNum[12]
	cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x, chenar_y + 100, matriceNum[16]
	cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x + 100, chenar_y + 100, matriceNum[20]
    cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x + 200, chenar_y + 100, matriceNum[24]
	cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x + 300, chenar_y + 100, matriceNum[28]
	cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x, chenar_y + 200, matriceNum[32]
	cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x + 100, chenar_y + 200, matriceNum[36]
    cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x + 200, chenar_y + 200, matriceNum[40]
	cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x + 300, chenar_y + 200, matriceNum[44]
	cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x, chenar_y + 300, matriceNum[48]
	cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x + 100, chenar_y + 300, matriceNum[52]
    cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x + 200, chenar_y + 300, matriceNum[56]
	cmp edx, 0
	jne _cont
	where_click pozX, pozY, chenar_x + 300, chenar_y + 300, matriceNum[60]	
	
	_cont:
	cmp numar1, 16
	jne _end
	
	mov esi,0
	mov ebx, 0
	
	mov esi,0
	mov ebx, 0
	_gasire_poz_16: ;cautam poz lui numar1 in sir
	cmp matriceNum[ebx], 16
	je end_gasire_poz_16
	inc esi
	add ebx, 4
	jmp _gasire_poz_16
	
	end_gasire_poz_16:
	mov ecx, esi
	mov esi,0
	mov ebx, 0
	_gasire_poz_numar: ;cautam poz lui numar1 in sir
	mov eax, numar2
	cmp matriceNum[ebx], eax
	je end_gasire_poz_numar
	inc esi
	add ebx, 4
	jmp _gasire_poz_numar
	
	end_gasire_poz_numar:
	;esi - avem poz numarului1
	;ecx - poz numarului 16
	
	push ecx
	dec ecx
	cmp ecx,esi
	jne _check1
	;schimbare val
	mov eax, matriceNum[esi*4]
	mov matriceNum[ecx*4 + 4], eax
	mov matriceNum[esi*4], 16
	
	_check1:
	pop ecx
	push ecx
	sub ecx,4
	cmp ecx,esi
	jne _check3
	;schimbare val
	mov eax, matriceNum[esi*4]
	mov matriceNum[ecx*4 + 16], eax
	mov matriceNum[esi*4], 16
	
	_check3:
	pop ecx
	push ecx
	add ecx,4
	cmp ecx,esi
	jne _check4
	;schimbare val
	mov eax, matriceNum[esi*4]
	mov matriceNum[ecx*4 - 16], eax
	mov matriceNum[esi*4], 16
	
	_check4:
	pop ecx
	push ecx
	inc ecx
	cmp ecx,esi
	jne _end
	;schimbare val
	mov eax, matriceNum[esi*4]
	mov matriceNum[ecx*4 - 4], eax
	mov matriceNum[esi*4], 16
	
	_end:
	pop ecx
	mov numar2, edx
	
endm

clean_mat macro len, pozX, pozY
	make_text_macro ' ', area, (pozX + len/2 - 5), (pozY + len/2 - 8)
	make_text_macro ' ', area, (pozX + len/2 + 5), (pozY + len/2 - 8)
	make_text_macro ' ', area, (pozX + 100 + len/2 - 5), (pozY + len/2 - 8)
	make_text_macro ' ', area, (pozX + 100 + len/2 + 5), (pozY + len/2 - 8)
	make_text_macro ' ', area, (pozX + 200 + len/2 - 5), (pozY + len/2 - 8)
	make_text_macro ' ', area, (pozX + 200 + len/2 + 5), (pozY + len/2 - 8)
	make_text_macro ' ', area, (pozX + 300 + len/2 - 5), (pozY + len/2 - 8)
	make_text_macro ' ', area, (pozX + 300 + len/2 + 5), (pozY + len/2 - 8)
	
	make_text_macro ' ', area, (pozX + len/2 - 5), (pozY + 100 + len/2 - 8)
	make_text_macro ' ', area, (pozX + len/2 + 5), (pozY + 100 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 100 + len/2 - 5), (pozY + 100 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 100 + len/2 + 5), (pozY + 100 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 200 + len/2 - 5), (pozY + 100 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 200 + len/2 + 5), (pozY + 100 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 300 + len/2 - 5), (pozY + 100 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 300 + len/2 + 5), (pozY + 100 + len/2 - 8)
	
	make_text_macro ' ', area, (pozX + len/2 - 5), (pozY + 200 + len/2 - 8)
	make_text_macro ' ', area, (pozX + len/2 + 5), (pozY + 200 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 100 + len/2 - 5), (pozY + 200 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 100 + len/2 + 5), (pozY + 200 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 200 + len/2 - 5), (pozY + 200 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 200 + len/2 + 5), (pozY + 200 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 300 + len/2 - 5), (pozY + 200 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 300 + len/2 + 5), (pozY + 200 + len/2 - 8)
	
	make_text_macro ' ', area, (pozX + len/2 - 5), (pozY + 300 + len/2 - 8)
	make_text_macro ' ', area, (pozX + len/2 + 5), (pozY + 300 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 100 + len/2 - 5), (pozY + 300 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 100 + len/2 + 5), (pozY + 300 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 200 + len/2 - 5), (pozY + 300 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 200 + len/2 + 5), (pozY + 300 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 300 + len/2 - 5), (pozY + 300 + len/2 - 8)
	make_text_macro ' ', area, (pozX + 300 + len/2 + 5), (pozY + 300 + len/2 - 8)
endm

verif_endgame macro matrice
;comparam numerel 2 cate 2, iar daca dieferenta lor este 1, ele sunt in ordine crescatoare
	mov ecx, matrice[0] 
	mov esi, 4
	mov edx, -1
	_loop:
		mov edx, -1
		mov ebx, matrice[esi]
		sub ebx, ecx
		cmp ebx, 1
		jne _cont
		mov edx, 1 ;edx va fi ca un marcator "ok" = 1 sirul e bun, 0 altfel
		mov ecx, matrice[esi]
		add esi, 4
		cmp esi, 60
		je _cont
	jmp _loop
	
	_cont:
	cmp edx, 1
	jne _end
	mov end_game, 1
	push offset mesaj_victorie
	push offset format_string
	add ebp, 8
	_end:
	
endm
;-----------

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click: ; event click
	;[ebp + arg2] -> X, [ebp + arg3]-> Y
	verif_click [ebp + arg2], [ebp + arg3]
	clean_mat cell_size, chenar_x, chenar_y
	init_mat matriceNum, cell_size, 100, 50
	verif_endgame matriceNum
	
evt_timer: ; event timer
	inc counterOK
	cmp end_game, 0
	jne _continue_cont
	cmp counterOK, 5
	jne _continue_cont
	inc counter
	mov counterOK, 0
	_continue_cont:
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	
	;scriem un mesaj

	draw_chenar 100,50,cell_size,0FF0000h ; procedura care ne genereaza chenarul
	init_mat matriceNum, cell_size, 100, 50
	;area_width/2 - (area_width/4) ar cam veni la mijloc pe axa oX
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

generare_random_mat proc
;generare matrice
	mov esi, 0
	_loop_rand: 
		rdtsc
		mov edx, 0 
		mov ecx, 17
		div ecx ;vom avea in edx numarul de inserat in sir
		mov ebx, 0
		
		cmp edx,0
		je _loop_cont
		cmp edx, 16
		je _loop_cont 
		_insert:
			cmp matriceNum[ebx], edx
			je _loop_rand
			cmp matriceNum[ebx], 0
			jne _insert_cont
			mov matriceNum[ebx], edx
			jmp _loop_cont
			_insert_cont:
			add ebx, 4
			cmp ebx, 60
		jne _insert
		
		;mov matriceNum[esi], edx
		_loop_cont:
		inc esi
		cmp esi, 60
		jne _loop_rand	
	_end_loop:
	
	mov eax, 16
	mov matriceNum[60], eax ;mereu pe ultima poz punem 16
	
	ret
generare_random_mat endp;

afisare_matrice proc
	;afisare matrice
	mov esi,0
	mov ebx,0
	mov edi,16
	for_mat:
		mov eax, matriceNum[esi]
		push eax
		push offset format_int
		call printf
		add esp,8
		
		inc ebx
		cmp ebx,4
		jne continuefor
		
		push offset format_new_line 
		call printf
		add esp, 4
		mov ebx, 0
		
		continuefor:
		add esi,4
		cmp esi, 64
	jne for_mat
	;end afisare matrice
	ret
afisare_matrice endp;

start:
	call generare_random_mat
	call afisare_matrice
	
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
