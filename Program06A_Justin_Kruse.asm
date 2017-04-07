TITLE Designing low-level I/O procedures    (Project06A_Justin_Kruse.asm)

; Author:	Justin Kruse
; CS 271 / Programming Assignment #6A             Date: 25 May 2016
; Description:	This program gets user input in the form of string values, then converts the string
;				to a floating point value and stores the float an array. Fills an array of 10 values.
INCLUDE Irvine32.inc

MAX_SIZE = 32

.data

userName	BYTE	MAX_SIZE + 1 DUP(0)														; string to be entered by user
userString	BYTE	MAX_SIZE + 1 DUP(0)														; string to be entered by user
userArray	REAL8	10 DUP(0.0)																; Floating Point Array											
intro_1		BYTE	"PROGRAMMING ASSIGNMENT 6 OPTION A: Desiging low-level I/O procedures", 10, "Written by: Justin Kruse", 10, 10, 0
intro_2		BYTE	"**EC:	EACH LINE NUMBERED AND A RUNNING TOTAL IS DISPLAYED", 10, 0
intro_3		BYTE	"**EC:	PROGRAM HANDLES *SIGNED* VALUES", 10, 0
intro_4		BYTE	"**EC:	ReadVal AND WriteVal PROCEDURES ARE RECURSIVE", 10, 0
intro_5		BYTE	"**EC:	FLOATING POINT IMPLEMENTED FOR ReadVal AND WriteVal", 10, 0
intro_6		BYTE	10, "NOTE: ", 9, "FLoating Point Values displayed to 0.01,", 10, 9, "but are accurate to 0.1 with rounding.", 10, 0
intro_7		BYTE	9, "Valid Entries: (+/-) X, X., .X, X.X", 10, 0
intro_8		BYTE	9, "X.XXXX entries are rounded to nearest 0.01", 10, 10, 0
prompt_1	BYTE	10, "Before we get started, please tell me your name: ", 0
greet_1		BYTE	10, "Hello, ", 0
prompt_2	BYTE	"Value ", 0
prompt_3	BYTE	": ", 0
prompt_4	BYTE	"Please enter a +/- floating point value (X.XX): ", 0
error_0		BYTE	10, "ERROR: You did not enter a valid floating point value,", 10, "       or it was too large of a value.", 10, 10, 0
result_0	BYTE	10, "You entered the following numbers: ", 10, 0
result_1	BYTE	"Running Sum: ", 9, 0
result_2	BYTE	"The total sum of your numbers is: ", 0
result_3	BYTE	"The average is: ", 0
tabby		BYTE	9, 0
period		BYTE	".", 10, 0
goodbye_1	BYTE	"Thanks for playing, it's been real fun! Good-bye, ", 0
goodbye_2	BYTE	"!", 10, 0

.code
main PROC
	; initialize floating point
	FINIT

	; introduce program
	push	OFFSET userName
	call	intro

	; get data from user and fill array
	push	OFFSET userString
	push	OFFSET userArray
	push	LENGTHOF userArray
	call	getData

	; display contents of array. sum and average
	push	OFFSET userString
	push	OFFSET userArray
	push	LENGTHOF userArray
	call	displayList
	
	; say goodbye and end
	push	OFFSET userName
	call	goodbye

	;fldcw  oldCtrlWord              ; restore control word

	exit	; exit to operating system
main ENDP

;----------------------------------------------------------------------
; Macros


getString MACRO promptAddress, stringAddress
	
	push	ecx
	push	edx
	displayString promptAddress
	mov		edx, stringAddress
	mov		ecx, MAX_SIZE
	call	ReadString
	pop		edx
	pop		ecx

ENDM



displayString MACRO stringOutAddress

	push	edx
	mov		edx, stringOutAddress
	call	WriteString
	pop		edx

ENDM



clearString MACRO stringAddress
	
	push	eax
	push	ecx
	push	edi
	mov		al, 0
	mov		edi, stringAddress
	mov		ecx, MAX_SIZE
	cld
	rep		stosb
	pop		edi
	pop		ecx
	pop		eax

ENDM

;-----------------------------------------------------------------

;-------------------------------------------------------------------------------------
intro PROC
;*	Procedure to introduce the program and get the user's name
;*	Receives:			userName
;*	Returns:			userName (reference)
;*	Preconditions:		push address of userName, MAX_NAME constant set for length of name
;*	Registers changed:	ecx, edx
;-------------------------------------------------------------------------------------
	pushad
	mov		ebp, esp						; set up stack frame

	mov		esi, [ebp + 36]					; address of userName

	;Introduce the program
	displayString	OFFSET intro_1
	displayString	OFFSET intro_2
	displayString	OFFSET intro_3
	displayString	OFFSET intro_4
	displayString	OFFSET intro_5
	displayString	OFFSET intro_6
	displayString	OFFSET intro_7
	displayString	OFFSET intro_8

	;Get user name
	getString		OFFSET prompt_1, esi
	displayString	OFFSET greet_1
	displayString	esi
	displayString	OFFSET period
	call	CrLf

	mov		esp, ebp						; remove locals from stack
	popad									; restore registers
	ret		4

intro ENDP

;-------------------------------------------------------------------------------------
getData PROC
;*	Procedure to get the number of composites to display.
;*	Receives:			none.
;*	Returns:			userN
;*	Preconditions:		MIN_VALUE, MAX_VALUE constants for limits.
;*	Registers changed:	eax, ebx, edx
;-------------------------------------------------------------------------------------

	pushad
	mov		ebp, esp						; set up stack frame

	mov		ecx, [ebp + 36]					; number of elements in array
	mov		edi, [ebp + 40]					; address of array
	mov		esi, [ebp + 44]					; string address

	sub			ESP, 12
	entryNum	EQU DWORD PTR [ebp-4]		; entry number
	runSum		EQU REAL8 PTR [ebp-12]		; running sum		
	
	mov		entryNum, 1
	
	; set runSum to zero
	fldz
	fstp	runSum	

L1:
	; call readVal

	displayString	OFFSET prompt_2
	mov		eax, entryNum
	call	WriteDec
	displayString	OFFSET prompt_3

	clearString esi

	push	edi
	push	esi
	push	1
	call	readVal

	cmp		eax, 0
	je		endif1

	; else an error occurred
	sub		edi, TYPE REAL8
	dec		entryNum
	displayString OFFSET error_0
	jmp		endif2

endif1:
	; show the running sum
	fld		REAL8 PTR [edi]
	fadd	runSum
	fstp	runSum

	displayString OFFSET result_1

	clearString esi

	lea		ebx, [ebp-12]
	push	ebx
	push	esi
	push	1
	call	WriteVal
	call	CrLf

endif2:
	add		ecx, eax
	add		edi, TYPE REAL8
	inc		entryNum
	dec		ecx
	jnz		L1
		
	mov		esp, ebp						; remove locals from stack
	popad									; restore registers
	ret		12

getData ENDP


;-------------------------------------------------------------------------------------
readVal PROC
;*	Procedure to recursively convert a string representation of a value to a floating
;*		point value.
;*	Receives:			address store float value, string addresss, 1.
;*						1 is used as a flag for the first time the recursive call happens.
;*						This was only implemented because of the requirement that the 
;*						readString happens inside readVal.
;*	Returns:			float value (reference), string value (reference),
;*						0 for no error, 1 for error.
;*	Preconditions:		push float address, string address, 1 in that order.
;*	Registers changed:	eax - rest of registers are preserved with pushad and popad
;-------------------------------------------------------------------------------------
	pushad								; save registers
	mov		ebp, esp					; set up stack frame

	mov		ebx, [ebp + 36]				; getString check - 1 = call getString, 0 = skip call getString
	mov		esi, [ebp + 40]				; string address
	mov		edi, [ebp + 44]				; address of float value
	mov		eax, 0

	sub				ESP, 48
	multiplier		EQU DWORD PTR [ebp-4]			; value to multiply to
	conversion		EQU DWORD PTR [ebp-8]			; value to convert from ascii value to dec
	signFlag		EQU DWORD PTR [ebp-12]			; flag for negative value
	asciiVal		EQU DWORD PTR [ebp-16]			; ascii value
	fraction		EQU REAL8 PTR [ebp-24]			; fractional part of the float
	badFlag			EQU DWORD PTR [ebp-28]			; flag for bad input
	hundred			EQU DWORD PTR [ebp-32]			; used for 100 value
	intVal			EQU DWORD PTR [ebp-36]			; integer expression of floating point value
	tempFPU			EQU REAL8 PTR [ebp-44]			; temporary float point value
	decCount		EQU DWORD PTR [ebp-48]			; number of decimal places from back of string
			
	mov		multiplier, 10
	mov		conversion, 48
	mov		hundred, 100
	
	mov		badFlag, 0
	mov		signFlag, 0
	mov		badFlag, 0
	mov		decCount, 0

	fldz
	fstp	fraction
	

	; This function is split into two parts:
	; Part 1 - calling validateString to check the string size
	; Part 2 - recursive calls on string characters to create a floating point value


	; Part 1 - verifying that user didn't enter in too many values, 
	;			or that value is too large for an integer value.


	; else string has no value, get one from user

	cmp		ebx, 0
	je		convertString
	; get string from user
	mov		esi, [ebp + 40]				; restore esi to start of string
	getString  OFFSET prompt_4, esi

	push	esi
	call	validateString
	cmp		eax, 1
	je		badInput

	; Part 2 - string is acceptable length and isn't too large for an int value

convertString:
	mov		esi, [ebp + 40]				; restore esi to start of string
	cld									; direction = forward
	lodsb								; read character from string
	cmp		al, 0						; check if null character
	je		leaveThis					; read done if null character
	cmp		al, 45						; check for negative sign
	jne		endIf0
	mov		signFlag, 1					; flag for negative sign
	jmp		checkFirstPos

endif0:
	cmp		al, 43						; check for positive sign '+'
	jne		endif1						 
	jmp		checkFirstPos				; check if this is the first position

checkFirstPos:							; if negative sign found, check if first position
	cmp		ebx, 1
	je		keepValueToPass
	jmp		badInput					; if not first position, bad input

endIf1:
	cmp		al, 46						; check if character is decimal place
	jne		endIf2
	jmp		passFraction				; it is decimal place, so go to recurse2

endif2:
	cmp		al, 48						; check for any other character not between 0 and 9
	jb		badInput
	cmp		al, 57
	ja		badInput

endIf3:
	mov		asciiVal, eax				; mov character value into asciiVal
	
	fld		REAL8 PTR [edi]				; load fpu value onto stack
	fimul	multiplier					; multiply value by 10
	fiadd	asciiVal
	fisub	conversion
	fstp	REAL8 PTR [edi]
	jmp		keepValueToPass

keepValueToPass:
	jmp		recurse
	
passFraction:
	jmp		recurse2

recurse:
	push	edi
	push	esi
	push	0
	call	readVal
	cmp		eax, 1
	je		badInput
	jmp		checkEBX

recurse2:
	lea		eax, [ebp-24]
	push	eax
	push	esi
	push	0
	call	readVal
	cmp		eax, 1
	je		badInput
	jmp		makeFraction

makeFraction:
	; determine how many times to divide by looking at how many places esi has to mov to find a decimal
	mov		eax, 0
	cld

findNULL:
	; find the beginning of the string
	lodsb
	cmp		al, 0
	je		findDecimal
	jmp		findNULL

findDecimal:
	; find the decimal place from the beginnning
	std
	dec		esi
	dec		esi
while1:
	cmp		decCount, 32
	jge		noDecimal
	lodsb
	cmp		al, 46				; comparing to ASCII value for '.'
	je		decimalFound
	inc		decCount
	jmp		while1

noDecimal:
	; no decimal was found, so just past adding as a fraction
	jmp		leaveThis

decimalFound:
	fld		fraction
	mov		ecx, decCount
	cmp		ecx, 0				; if ecx is 0, don't do any dividing
	je		addFraction
L1:
	; div by 10 for the number of decimal places from the end of the string
	fidiv	multiplier
	loop	L1
	fstp	fraction

addFraction:
	fld		REAL8 PTR [edi]			; add fractional part of string to float value
	fadd	fraction
	fstp	REAL8 PTR [edi]
	jmp		checkEBX

badInput:
	mov		badFlag, 1				; flag for bad input
	jmp		leaveThis
		
checkEBX:
	cmp		ebx, 1					; of this is the first call on the function, apply the sign
	je		checkSign
	jmp		leaveThis

checkSign:
	; check sign					; check for sign flag value, and apply sign - 1 is negativ, 0 is positve
	cmp		signFlag, 0
	je		roundValue
	fld		REAL8 PTR [edi]
	fchs
	fstp	REAL8 PTR [edi]
	jmp		roundValue

	;
	; Rounding the value
	; Here is where the limit of 21474836.47 applies. 
	; After multiplying by 100, integer value becomes 2147483647.
	;

roundValue:												
	; adjust value so that only 2 decimal places show
	fld		REAL8 PTR [edi]
	fimul	hundred
	fst		tempFPU
	fisttp	intVal
	
	push	intVal

	fld		tempFPU
	fisub	intVal
	fimul	multiplier
	fisttp	intVal
	cmp		intVal, 0
	jge		round4postive
	jmp		round4negative

round4postive:
	cmp		intVal, 5
	jl		endIf4
	pop		intVal
	inc		intVal
	push	intVal

round4negative:
	cmp		intVal, -5
	jg		endIf4
	pop		intVal
	dec		intVal
	push	intVal

endif4:
	pop		intVal
	fldz
	fiadd	intVal
	fidiv	hundred
	fstp	REAL8 PTR [edi]

leaveThis:
	mov		ebx, badFlag
	lea		ecx, [ebp + 28]
	mov		[ecx], ebx
	mov		esp, ebp					; remove locals from stack
	popad								; restore registers		
	ret		12

readVal endP


;-------------------------------------------------------------------------------------
displayList PROC
;*	Procedure to display the elements of an array, 3 elements per row. Also displays
;*			the sum and average of values in the array.
;*	Receives:			array (reference)
;*						array size (value)
;*						string address
;*	Returns:			none (modifies array by reference)
;*	Precondition:		prior to a call:
;*						push string address, push address of array, push array size
;*						in that order
;*	Registers changed:	registers are preserved with pushad and popad
;-------------------------------------------------------------------------------------
	pushad								; save registers
	mov		ebp, esp					; set up stack frame

	mov		ecx, [ebp + 36]				; number of elements in array
	mov		edi, [ebp + 40]				; address of array
	mov		esi, [ebp + 44]				; address of userString

	sub			esp, 24
	onLine		EQU DWORD PTR [ebp-4]
	sumFPU		EQU REAL8 PTR [ebp-12]
	aveFPU		EQU REAL8 PTR [ebp-20]
	ten			EQU DWORD PTR [ebp-24]

	mov		onLine, 0
	mov		ten, 10
	
	fldz
	fst		sumFPU
	fstp	aveFPU
	
	displayString	OFFSET result_0
	call	CrLf

L1:
	; write Val calls
	clearString esi
	
	push	edi
	push	esi
	push	1
	call	WriteVal

	inc		onLine
	cmp		onLine, 3								; show only 3 values per row
	jge		newLine									; new line if there are already 3 values in row
	displayString	OFFSET tabby
	displayString	OFFSET tabby
	jmp		endIf1
newLine:
	mov		onLine, 0								; reset how many are in row after new line
	call	CrLf
endIf1:
	fld		sumFPU
	fadd	REAL8 PTR [edi]
	fstp	sumFPU									; running sum

	add		edi, TYPE REAL8
	Loop	L1

	call	CrLf

	; show the sum
	clearString esi

	call	CrLf
	displayString OFFSET result_2

	; display the sum of all values in the array
	lea		ebx, [ebp-12]
	push	ebx
	push	esi
	push	1
	call	WriteVal
	call	CrLf

	; show the average
	clearString esi

	call	CrLf
	displayString OFFSET result_3

	fld		sumFPU
	fidiv	ten								; divide sum by the number of elements in the array to get average
	fstp	aveFPU

	; display the average
	lea		ebx, [ebp-20]
	push	ebx
	push	esi
	push	1
	call	WriteVal
	call	CrLf
	call	CrLf

displayDone:
	mov		esp, ebp					; remove locals from stack
	popad								; restore registers		
	ret		12

displayList ENDP


;-------------------------------------------------------------------------------------
writeVal PROC
;*	Procedure to convert a floating point value to a string, then displays the string
;*		to the console.
;*	Receives:			Address of float value
;*						Address of string value
;*						1 for first call flag. Recursive calls use 0.
;*	Returns:			none. modifies string and floating point values.
;*	Preconditions:		Push in the following order:
;*						Address of float
;*						Address of string
;*						value of 1
;*	Registers changed:	registers are preserved with pushad and popad
;-------------------------------------------------------------------------------------
	pushad								; save registers
	mov		ebp, esp					; set up stack frame

	mov		ebx, [ebp + 36]				; first call flag
	mov		edi, [ebp + 40]				; string address
	mov		esi, [ebp + 44]				; address of float value
				

	sub			ESP, 28
	intVal		EQU DWORD PTR [ebp-4]		; integer part of fpu
	rightSide	EQU REAL8 PTR [ebp-12]		; right side of decimal
	leftSide	EQU REAL8 PTR [ebp-20]
	hundred		EQU DWORD PTR [ebp-24]		; hundred value
	ten			EQU DWORD PTR [ebp-28]		; ten value

	mov		hundred, 100
	mov		ten, 10

	; first check if negative sign needs to be added
	fld		REAL8 PTR [esi]
	fimul	hundred
	fisttp	intVal

	cmp		intVal, 0
	jge		endIf1							; int >= 0

	; yes, intVal < 0, so add negative sign to string
	mov		al, 45							; load al with ASCII value for negative sign
	stosb									; negative sign added to string

endIf1:
	; set intVal and righSide values
	fld		REAL8 PTR [esi]
	fabs
	fst		rightSide
	fisttp	intVal
	
	fld		rightSide
	fisub	intVal
	fstp	rightSide

	; if intVal is zero and if ebx is 1, then print a 0
	cmp		intVal, 0
	jnz		endIf2
	cmp		ebx, 0
	je		endIf3
	mov		al, 48							; load al with ASCII value for zerp
	stosb									; zero added to front of string
	jmp		endIf3
	
endIf2:
	; if intVal is less than 10, then print, else divide by 10 and recurse
	cmp		intVal, 10
	jge		recurse1
	; Add 48 to intVal to get ASCII representation of value
	add		intVal, 48
	mov		al, BYTE PTR intVal				; mov ascii value into al
	stosb									; insert intVal into string
	jmp		endIf3

recurse1:
	mov		edx, 0
	mov		eax, intVal
	div		ten
	mov		intVal, eax

	fldz
	fiadd	intVal
	fstp	leftSide
	
	lea		esi, [ebp-20]
	push	esi
	push	edi
	push	0
	call	writeVal

restoreEDI:
	cmp		BYTE PTR [edi], 0
	je		insertRemainder
	add		edi, 1
	jmp		restoreEDI

insertRemainder:
	mov		al, dl
	add		al, 48
	stosb

endIf3:

checkDecimalPoint:
	cmp		ebx, 0
	je		endIf4
	mov		al, 46				; load al with ASCII value for decimal point
	stosb						; decimal point added to string

endIf4:
	; add right side of decimal to string
	fld		rightSide
	fimul	hundred
	fst		rightSide
	fisttp	intVal

	; if intVal is zero, end recursive call
	cmp		intVal, 0
	je		checkEBX
	
	; if intVal is less than 10, print a zero, then print intVal
	cmp		intVal, 10
	jge		recurse2
	mov		al, 48							; load al with ASCII value for zer0
	stosb									; zero added to front of string
	add		intVal, 48
	mov		al, BYTE PTR intVal				; mov ascii value into al
	stosb									; insert intVal into string
	jmp		checkEBX								

recurse2:

	; else perform recursive call
	fldz
	fiadd	intVal
	fstp	rightSide
	
	lea		esi, [ebp-12]
	push	esi
	push	edi
	push	0
	call	writeVal
	
checkEBX:
	cmp		ebx, 0
	je		writeDone
	jmp		showString

showString:
	;jmp		okToDisplay
	; final check on string to fill zeros
	std
	mov		esi, edi
findDecimal:
	lodsb
	cmp		al, 46
	je		decimalFound
	jmp		findDecimal

decimalFound:
	cld
	inc		esi
	inc		esi
	mov		ecx, 2
L2:
	lodsb
	cmp		al, 0
	je		insertZero
	jmp		decimalOK
insertZero:
	mov		edi, esi
	dec		edi
	mov		al, 48
	stosb								; adding zeros to end of string so that display is X.XX
decimalOK:
	loop	L2

okToDisplay:
	mov		edi, [ebp + 40]	
	displayString	edi

writeDone:
	mov		esp, ebp					; remove locals from stack
	popad								; restore registers		
	ret		12

writeVal endP



;-------------------------------------------------------------------------------------
goodbye PROC
;*	Procedure to display a goodbye message to user, using userName address
;*	Receives:			userName
;*	Returns:			userName (reference)
;*	Preconditions:		push address of userName, MAX_NAME constant set for length of name
;*	Registers changed:	registers are preserved with pushad and popad
;-------------------------------------------------------------------------------------
	pushad
	mov		ebp, esp						; set up stack frame

	mov		esi, [ebp + 36]					; address of userName

	;Say goodbye
	displayString OFFSET goodbye_1
	displayString esi
	displayString OFFSET goodbye_2
	call	CrLf

	mov		esp, ebp						; remove locals from stack
	popad									; restore registers
	ret		4

goodbye ENDP




;-------------------------------------------------------------------------------------
validateString PROC
;*	Procedure to verify that string length doesn't exceed 30 characters. Looks for a
;*    decimal value in string to determine number of digits of integer equivalent.
;*    If the number of digits is equal to 8, does a character by character comparison
;*    to ensure it that the value would not exceed 21474836.47.
;*	Receives:			string to be validated
;*	Returns:			eax is changed for referencing an error after the proc call.
;*	Preconditions:		push address of string onto stack before calling procedure.
;*	Registers changed:	eax - rest of registers are preserved with pushad and popad
;-------------------------------------------------------------------------------------
	pushad								; save registers
	mov		ebp, esp					; set up stack frame
	
	mov		esi, [ebp + 36]				; string address
	mov		eax, 0

	sub				ESP, 8
	strCount		EQU DWORD PTR [ebp-4]			; count number of values in string
	decFound		EQU DWORD PTR [ebp-8]			; flag for finding the decimal
			
	mov		strCount, 0
	mov		decFound, 0
	

	; This function is split into two parts:
	; Part 1 - iterating through the string just to verify it's size
	; Part 2 - recursive calls on string characters to create a floating point value


	; Part 1 - verifying that user didn't enter in too many values, or that value is too large
	;			for an integer value.

checkLength:
	mov		eax, 0						; eax counts total length
	mov		ecx, 0						; ecx counts until decimal
	cld									; direction = forward
	lodsb								; read character from string
	cmp		al, 0						; check if null character
	je		checkLengthDone				; read done if null character
	cmp		al, 46
	jl		checkLength					; may be a + or - sign
	je		markDecimalLength
	inc		strCount
	cmp		strCount, 30						; user entered too many values
	jge		badInput				
	jmp		checkLength					; repeat until NULL value is found

markDecimalLength:
	mov		decFound, 1
	mov		ecx, strCount
	inc		strCount
	cmp		strCount, 30
	jge		badInput					; user entered too many characters
	cmp		ecx, 8
	jg		badInput					; integer value is too large
	jmp		checkLength

checkLengthDone:
	cmp		decFound, 1
	je		checkIntValue
	mov		ecx, strCount		
	cmp		strCount, 30
	jge		badInput					; user entered too many characters	

checkIntValue:		
	cmp		ecx, 0
	je		stringSizeGood				; int value is 0, jump to converting for decimal value
	cmp		ecx, 8						; check how many decimal places from the beginning 
	jg		badInput
	je		checkMaxVal
	jmp		stringSizeGood				; int value will be less than 8 digits

	;
	; if there are at least 8 places until decimal, need to compare against the value 21474836.47.
	; 21474836.47 is the largest value that can be used because of rounding at the end. There is a multiple by 100.
	;

checkMaxVal:
	mov		esi, [ebp + 36]				; restore esi to start of string
checkAgainst2:
	lodsb								; look at spot 1
	cmp		al, 50						; check for + or - sign
	jl		checkAgainst2				; load next character
	cmp		al,	52
	jg		badInput
	jl		stringSizeGood				; string character is less than 2, jump to converting
checkAgainst1:
	lodsb								; look at spot 2
	cmp		al,	49
	jg		badInput
	jl		stringSizeGood				; string character is less than 1, jump to converting
checkAgainst4:
	lodsb								; look at spot 3
	cmp		al,	52
	jg		badInput
	jl		stringSizeGood				; string character is less than 4, jump to converting
checkAgainst7:
	lodsb								; look at spot 4
	cmp		al,	55
	jg		badInput
	jl		stringSizeGood				; string character is less than 7, jump to converting
checkAgainst4_1:
	lodsb								; look at spot 5
	cmp		al,	52
	jg		badInput
	jl		stringSizeGood				; string character is less than 4, jump to converting
checkAgainst8:
	lodsb								; look at spot 6
	cmp		al,	56
	jg		badInput
	jl		stringSizeGood				; string character is less than 8, jump to converting
checkAgainst3:
	lodsb								; look at spot 7
	cmp		al,	51
	jg		badInput
	jl		stringSizeGood				; string character is less than 3, jump to converting
checkAgainst6:
	lodsb								; look at spot 8
	cmp		al,	54
	jg		badInput
	jl		stringSizeGood				; string character is less than 6, jump to converting
checkAgainstDec:
	lodsb								; look at spot 9 - should be a decimal
	cmp		al,	46
	je		checkFirstDec
	jmp		badInput					; if not a decimal value, then bad string
checkFirstDec:
	lodsb								; look at spot 10 - first place on the right of decimal
	cmp		al,	52
	jg		badInput
	jl		stringSizeGood				; string character is less than 4, jump to converting
checkSecondDec:
	lodsb								; look at spot 11 - first place on the right of decimal
	cmp		al,	55
	jge		badInput
	jl		stringSizeGood				; string character is less than 7, jump to converting
	
	; if it gets here, then string value is ok
stringSizeGood:
	mov		eax, 0
	jmp		validateDone

badInput:
	mov		eax, 1
	
validateDone:
	lea		ecx, [ebp + 28]
	mov		[ecx], eax 	
	mov		esp, ebp					; remove locals from stack
	popad								; restore registers		
	ret		4

validateString ENDP

	
END main





