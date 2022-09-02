.equ DDR_HIGH_WORD, 0x3FFFFFFC
.global _start

.section .text

_start:
	// Here your execution starts
	b check_input
	b exit

	
check_input:
	// You could use this symbol to check for your input length
	// you can assume that your input string is at least 2 characters 
	// long and ends with a null byte
	ldr r0, =input //Load input word into two different registers
	ldr r1, =input //
	
	
find_end:
	//To find the length of the string i will need to iterate til i find the 
	//null character
	ldrb r2, [r0] //Load the byte value where the pointer is currently at in r0 into r2
	cmp r2, #0    //Compare the value to the null character in ASCII
	subeq r0, r0, #1  //As the pointer is at the null char we have to move it back
	beq check_value_r0 
	add r0, r0, #1
	bne find_end        //Jump back to find_length until the null is found

check_value_r0:
	//Check to see if the value 
	ldrb r2, [r0]  //Load r2 with wherever the r0 pointer is
	bl check_space_r0 //Check if the value is space
	bl check_higher_r0 //Check if value is lower than Z
	b check_value_r1  //If the value in r0 has gone through all the checks we can now test the second value
	
check_space_r0:
	//Checking if the value is equal to space if it is then skip it and start the process over
	cmp r2, #32
	itt eq
	subeq r0, r0, #1
	beq check_value_r0
	bx lr
check_higher_r0:
	//Check if the value is lower than 90. If it is not then return. If it is then check the lower
	cmp r2, #90
	ble check_lower_r0
	bx lr
check_lower_r0:
	//Check if the value is higher than 41. If it is then its a CAPS char. Add 32 to make it caps char
	cmp r2, #41
	addge r2, r2, #32
	b check_value_r1 //If its in the range 41-90 the char is a letter and we can check the next value
					 //If not then its probably a number and we can still go on to check the next value
					 
check_value_r1:
	ldrb r3, [r1]  //Load r3 with wherever the r1 pointer is
	bl check_space_r1 //Check if the value is space
	bl check_higher_r1 //Check if value is lower than Z
	b compare  //If the value in r0 has gone through all the checks we can now test the values against eachother
check_space_r1:
	//Checking if the value is equal to space if it is then skip it and start the process over
	cmp r3, #32
	itt eq
	addeq r1, r1, #1
	beq check_value_r1
	bx lr
check_higher_r1:
	//Check if the value is lower than 90. If it is not then return. If it is then check the lower
	cmp r3, #90
	ble check_lower_r1
	bx lr
check_lower_r1:
	//Check if the value is higher than 41. If it is then its a CAPS char. Add 32 to make it caps char
	cmp r3, #41
	addge r3, r3, #32
	b compare //If its in the range 41-90 the char is a letter and we can check the next value
					 //If not then its probably a number and we can still go on to compare the results

compare:
	//Now that the two values has been skipped and checked again(space), turned lowercase(CAPS) or 
	//passed through(number or lowercase) they can be compared to eachother.
	//If they are not equal then its not a palindrome.
	//If they are equal then we have to check every char until the pointers pass eachother at the middle.
	//When this condition is met then we can verify we have a palindrome. 
	cmp r2, r3
	bne palindrom_not_found
	beq check_pointers
	
check_pointers:
	//Check the pointers to see if we have iterated through all the chars.
	//If not then we can add/sub the pointers and do another check. Eventually we will find a char that is not equal
	//or the pointers will meet in the middle
	cmp r0, r1
	ble palindrome_found
	sub r0, r0, #1
	add r1, r1, #1
	b check_value_r0

palindrome_found:
	// Switch on only the 5 rightmost LEDs
	// Write 'Palindrome detected' to UART
	ldr r2, =0b0000011111
	bl start_led
	ldr r3, =is_palindrome
	mov SP,#DDR_HIGH_WORD // highest memory word address
	b JTAG_LOOP
	
	
palindrom_not_found:
	// Switch on only the 5 leftmost LEDs
	// Write 'Not a palindrome' to UART
	ldr r2, =0b1111100000
	bl start_led
	ldr r3, =not_palindrome
	mov SP,#DDR_HIGH_WORD // highest memory word address
	b JTAG_LOOP
	
start_led:
	ldr r1, =0xFF200000 // LED register base address
    str r2, [r1]   //Store the bits in the base address
    bx lr           //Go back

JTAG_LOOP:
	//Using the jtag from DE1-SoC
	LDRB R0, [R3] //Loads the word into
	CMP R0, #0
	BEQ exit // string is null-terminated
	BL PUT_JTAG // send the character in R0 to UART
	ADD R3, R3, #1
	B JTAG_LOOP
PUT_JTAG:
	LDR R1, =0xFF201000 // JTAG UART base address
	//LDR R2, [R1, #4] // read the JTAG UART control register
	//LDR R3, =0xFFFF
	//ANDS R2, R2, R3 // check for write space
	//BEQ END_PUT // if no space, ignore the character
	STR R0, [R1]
END_PUT:
	BX LR

exit:
	// Branch here for exit
	b exit
	

.section .data
.align
	// This is the input you are supposed to check for a palindrome
	// You can modify the string during development, however you
	// are not allowed to change the label 'input'!
	// input: .asciz "level"
	// input: .asciz "8448"
     input: .asciz "KayAk"
    // input: .asciz "step on no pets"
    // input: .asciz "Never odd or even"
	
	is_palindrome: .asciz "Palindrome detected\n"
  	not_palindrome: .asciz "Not a palindrome\n"


.end