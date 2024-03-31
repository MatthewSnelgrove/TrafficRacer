###################################################################### 
# CSCB58 Summer 2022 Project 
# University of Toronto, Scarborough 
# 
# Student Name: Matthew Snelgrove, Student Number: 1008263139, UTorID: snelgr18 
# 
# Bitmap Display Configuration:  
# - Unit width in pixels: 8  
# - Unit height in pixels: 8  
# - Display width in pixels: 256  
# - Display height in pixels: 516  
# - Base Address for Display: 0x10008000 ($gp) 

# Basic features that were implemented successfully 
# - Display number of remaining lives
# - Different cars moving at different speeds
# - Gameover/retry screen
# 
# Additional features that were implemented successfully 
# - Press spacebar to toggle shield. makes you invincible. recharges over time
# - Live score
# - Go to new level with faster car speeds after completing previous level
#  
# Link to the video demo 
# - https://utoronto.zoom.us/rec/share/uI_WYBMm-j6HseJL9h9ReKqZ-7YDCmls0uFM1bhO18_R0lK9dyn1vbUTee7QmnES.22R3owA-pG0WyG0a
# 
# Any additional information that the TA needs to know: 
# - When out of lives press w to retry or s to exit
#  
######################################################################
.data 
displayAddress:      	.word 0x10008000
fps:			.word 50 	#frames per second
mspf:			.word 20 	#milliseconds per frame
lives:			.word 2		#end level when below 0
cars:			.space 180	#1 player car and 8 cars each with x, y, speed, moveCarry, colour stored in words
lineHeight:		.word -3	#height to draw lines
paintBuffer:		.space 8192	#set pixels here then copy
playerSpeed:		.word -700	#initial speed of player
speedIncrement:		.word 150	#amount of speed change when going faster or slower
enemySpeed:		.word 400	#base speed of enemy cars. actual cars get +-75 added to this
levelProgress:		.word 0		#increase by 1 each frame
shieldCharge:		.word 0		#increase by 1 each frame not in use. drain 10 each frame in use. max of 250
isShielded:		.word 0		#whether or not playeris using shield
laneTimers:		.space 16	#each lane has a timer that tracks number of frames to next spawn
lastCars:		.space 16	#each lane toggles between 0 and 1 representing the 2 memory locations of the cars for the lane
playerMoveAmt:		.word 0		#pixels moved by player this frame
string:			.asciiz	"\n"



.text  

.globl main

main:

Init:
	la $t0, cars		#get reference to cars
	li $t1, 0xff0000	
	sw $t1, 16($t0)		#set player colour
	#set enemy x positions
	li $t1, 1
	sw $t1, 20($t0)
	sw $t1, 40($t0)
	li $t1, 9
	sw $t1, 60($t0)
	sw $t1, 80($t0)
	li $t1, 18
	sw $t1, 100($t0)
	sw $t1, 120($t0)
	li $t1, 26
	sw $t1, 140($t0)
	sw $t1, 160($t0)
	#set lastCars
	la $t0, lastCars
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	sw $zero, 12($t0)

Reset:
	la $t0, cars		#get reference to cars
	li $t1, 18		
	sw $t1, 0($t0)		#set player x to 18
	li $t1, 47	
	sw $t1, 4($t0)		#set player y to 47
	lw $t1, playerSpeed	#load startSpeed
	sw $t1, 8($t0)		#set player speed
	sw $zero, 12($t0)	#set player carry to 0
	sw $zero, shieldCharge	#remove any remaining shield
	sw $zero, isShielded
	li $t1, 24		#counter
	li $t2, 184		#max counter
	add $t1, $t1, $t0	#relative to cars
	add $t2, $t2, $t0	#relative to cars
	li $t3, 64		#y=64 below screen
	resetEnemyYLoop:
	bgt $t1, $t2, resetEnemyYLoopEnd
	sw $t3, 0($t1)		#set car y to 64 (offscreen)
	addi $t1, $t1, 20	#go to next car
	j resetEnemyYLoop
	resetEnemyYLoopEnd:
	sw $zero, levelProgress
	li $t1, 0
	li $t2, 12
	la $t3, laneTimers
	add $t1, $t1, $t3	#relative to laneTimers
	add $t2, $t2, $t3	#relative to laneTimers
	lw $t4, fps
	mul $t4, $t4, 5	#5*fps
	resetLaneTimersLoop:
	bgt $t1, $t2, resetLaneTimersLoopEnd
	li $v0, 42  	#rng from 0 to 5*fps
	li $a0, 0  	#id
	move $a1, $t4  	#max number
	syscall
	sw $a0, 0($t1)	#set lane timer to random number
	addi $t1, $t1, 4	#go to next lane	
	j resetLaneTimersLoop
	resetLaneTimersLoopEnd:
	
	j GameLoop
	
LevelComplete:
	sw $zero, levelProgress		#set level progress to 0
	lw $t0, enemySpeed		#increase enemy/player speed by 300
	addi $t0, $t0, 300
	sw $t0, enemySpeed
	lw $t0, playerSpeed
	addi $t0, $t0, -300
	sw $t0, playerSpeed
	lw $t0, speedIncrement		#increase speed increment by 150
	addi $t0, $t0, 150
	sw $t0, speedIncrement
	j Reset
	
	
GameOver:
	#paint reset button
	#paint exit button
	#paint everything red
	li $t3, 0xff0000
	li $t0, 0		#counter
	li $t1, 8188		#max count
	gameOverPaintLoop:
		bgt $t0, $t1, gameOverPaintLoopEnd		#end of loop
		add $t2, $s0, $t0	#set $t2 to paintBufferAddress + 4 * loop iteration
		sw $t3, 0($t2)		#paint pixel
		addi $t0, $t0, 4		#increment by 4
		j gameOverPaintLoop
	gameOverPaintLoopEnd:
	#####paint retry/exit options of screen#####
	li $t3, 0xffffff
	#w
	sw $t3, 2972($s0)		#paint pixel
	sw $t3, 3100($s0)		#paint pixel
	sw $t3, 3232($s0)		#paint pixel
	sw $t3, 3108($s0)		#paint pixel
	sw $t3, 3240($s0)		#paint pixel
	sw $t3, 2988($s0)		#paint pixel
	sw $t3, 3116($s0)		#paint pixel
	#:1
	sw $t3, 3000($s0)		#paint pixel
	sw $t3, 3256($s0)		#paint pixel
	#retry
	sw $t3, 2756($s0)		#paint pixel
	sw $t3, 2632($s0)		#paint pixel
	sw $t3, 2760($s0)		#paint pixel
	sw $t3, 2888($s0)		#paint pixel
	sw $t3, 2508($s0)		#paint pixel
	sw $t3, 2636($s0)		#paint pixel
	sw $t3, 2764($s0)		#paint pixel
	sw $t3, 2892($s0)		#paint pixel
	sw $t3, 3020($s0)		#paint pixel
	sw $t3, 3404($s0)		#paint pixel
	sw $t3, 2768($s0)		#paint pixel
	sw $t3, 3408($s0)		#paint pixel
	sw $t3, 2772($s0)		#paint pixel
	sw $t3, 3412($s0)		#paint pixel
	sw $t3, 2904($s0)		#paint pixel
	sw $t3, 3288($s0)		#paint pixel
	sw $t3, 3036($s0)		#paint pixel
	sw $t3, 3164($s0)		#paint pixel
	#s
	sw $t3, 5024($s0)		#paint pixel
	sw $t3, 5152($s0)		#paint pixel
	sw $t3, 5536($s0)		#paint pixel
	sw $t3, 4900($s0)		#paint pixel
	sw $t3, 5284($s0)		#paint pixel
	sw $t3, 5668($s0)		#paint pixel
	sw $t3, 5032($s0)		#paint pixel
	sw $t3, 5416($s0)		#paint pixel
	sw $t3, 5544($s0)		#paint pixel
	#:2
	sw $t3, 5176($s0)		#paint pixel
	sw $t3, 5432($s0)		#paint pixel
	#exit
	sw $t3, 5068($s0)		#paint pixel
	sw $t3, 5580($s0)		#paint pixel
	sw $t3, 5200($s0)		#paint pixel
	sw $t3, 5456($s0)		#paint pixel
	sw $t3, 5332($s0)		#paint pixel
	sw $t3, 5208($s0)		#paint pixel
	sw $t3, 5464($s0)		#paint pixel
	sw $t3, 5084($s0)		#paint pixel
	sw $t3, 5596($s0)		#paint pixel
	
	#####paint retry/exit options of screen#####
	jal PaintBufferToDisplay
	waitForReset:
	li $t0, 0xffff0000 	#key pressed address
	lw $t1, 0($t0)		#1 if key pressed
	beq $t1, 1, gameOverKeyPressed	#exit loop if key pressed
	li $v0, 32 		#sleep
	lw $a0, mspf
	syscall
	j waitForReset
	gameOverKeyPressed:
		lw $t2, 4($t0) # this assumes $t0 is set to 0xfff0000  
		beq $t2, 0x77, gameOverWPressed # ASCII code of 'w' is 0x77 or 119 in decimal
		beq $t2, 0x73, gameOverSPressed # ASCII code of 's' is 0x73 or 115 in decimal
		j waitForReset	#any other key pressed
	gameOverWPressed:
		li $t3, 2
		sw $t3, lives
		j Reset
	gameOverSPressed:
	li $t3, 0x000000
	li $t0, 0		#counter
	li $t1, 8188		#max count
	exitPaintLoop:
		bgt $t0, $t1, exitPaintLoopEnd		#end of loop
		add $t2, $s0, $t0	#set $t2 to paintBufferAddress + 4 * loop iteration
		sw $t3, 0($t2)		#paint pixel
		addi $t0, $t0, 4		#increment by 4
		j exitPaintLoop
	exitPaintLoopEnd:
		jal PaintBufferToDisplay
		li $v0, 10
		syscall

GameLoop:
	jal Update		#game logic
	jal Paint		#paint to screen
	li $v0, 32 		#sleep
	lw $a0, mspf
	syscall
	j GameLoop

Update:
	addi $sp, $sp, -4
	sw $ra, 0($sp)		#push ra on stack
	lw $t0, levelProgress	#increase level progress
	addi $t0, $t0, 1
	sw $t0, levelProgress	#save new progress
	bgt $t0, 1500, LevelComplete	#if level progress high enough (1500 = 30 seconds at 50 fps) go to next
	jal GetPlayerMoveAmt
	lw $t0, playerMoveAmt	#get playerMoveAmt
	lw $t1, lineHeight	#load lineHeight
	sub $t1, $t1, $t0	#updateLineHeight
	#make sure line height is negative so y - lineHeight is positive
	decreaseLineHeight:
	blez $t1, skipDecreaseLineHeight
	addi $t1, $t1, -8
	j decreaseLineHeight
	skipDecreaseLineHeight:
	sw $t1, lineHeight	#save lineHeight
	

	lw $t0, shieldCharge	#decrease remaining invincibility if player has any
	lw $t1, isShielded
	beqz $t1, notShieldUpdate
	addi $t0, $t0, -11
	notShieldUpdate:
	addi $t0, $t0, 1
	sw $t0, shieldCharge
	bgtz $t0, shieldChargeLeftUpdate
	sw $zero, isShielded	#turn off shield
	shieldChargeLeftUpdate:

	jal SpawnStuff
	jal MoveAllCars
	jal CheckCollisions


	lw $ra, 0($sp)		#pop ra from stack
	addi $sp, $sp, 4
	
	li $t0, 0xffff0000 
	lw $t1, 0($t0) 
	beq $t1, 1, keyPressed	#skip return if key pressed
	jr $ra			#return
		
	keyPressed:
	la $t3, cars	#reference to player
	lw $t4, 0($t3)	#set t4 to player x
	lw $t5, 8($t3)	#set t5 to player speed
	lw $t6, playerSpeed	#set $t6 to startSpeed
	lw $t7, speedIncrement	#set $t7 to speedIncrement
	lw $t2, 4($t0) # this assumes $t0 is set to 0xfff0000  
	beq $t2, 0x61, aPressed # ASCII code of 'a' is 0x61 or 97 in decimal 
	beq $t2, 0x64, dPressed # ASCII code of 'd' is 0x64 or 100 in decimal
	beq $t2, 0x77, wPressed # ASCII code of 'w' is 0x77 or 119 in decimal
	beq $t2, 0x73, sPressed # ASCII code of 's' is 0x73 or 115 in decimal
	beq $t2, 0x20, spacePressed # ASCII code of 'spacebar' is 0x20 or 32 in decimal
	jr $ra
	spacePressed:
		lw $t1, isShielded
		bgtz $t1, notShielded
		sw $zero, isShielded
		notShielded:
		li $t2, 1
		sw $t2, isShielded
		lw $t3, shieldCharge
		addi $t3, $t3, -10
		sw $t3, shieldCharge
		jr $ra
	aPressed:
		addi $t4, $t4, -1	#decrease x by 1decimal
		sw $t4, 0($t3)	#update player x
		jr $ra
	dPressed:
		addi $t4, $t4, 1	#increase x by 1
		sw $t4, 0($t3)	#update player x
		jr $ra
	wPressed:
		blt $t5, $t6, skipSpeedChange	
		sub $t5, $t5, $t7	#increase speed by speedIncrement
		sw $t5, 8($t3)	#update player x
		jr $ra
	sPressed:
		bgt $t5, $t6, skipSpeedChange
		add $t5, $t5, $t7	#decrease speed by speedIncrement
		sw $t5, 8($t3)	#update player x
		jr $ra
	skipSpeedChange:
	jr $ra
	
CheckCollisions:
	
	la $t0, cars	#load address of cars in $t0
	lw $t1, 0($t0)	#load player x into $t1
	lw $t2, 4($t0)	#load player y into $t1
	addi $t8, $t1, 4	#player x + 4
	addi $t9, $t2, 7	#player y + 7
	#check is player colliding with walls
	bltz $t1, HandleCollision	#player colliding with left wall
	bge $t1, 28, HandleCollision	#player colliding with right wall
	
	#check if player colliding with cars
	#####
	addi $t3, $t0, 20	#cars address
	addi $t4, $t0, 160	#max value
	CarCollisionCheck:
	bgt $t3, $t4, CarCollisionCheckEnd
	lw $t5, 0($t3)	#load car x
	addi $t6, $t5, 4	#car x + 4
	blt $t6, $t1, noCarCollision	#car left of player
	bgt $t5, $t8, noCarCollision	#car right of player
	lw $t5, 4($t3)	#load car y
	addi $t6, $t5, 7	#car y + 7
	blt $t6, $t2, noCarCollision	#car above player
	bgt $t5, $t9, noCarCollision	#car below of player
	li $v0, 1
	li $a0, 1
	syscall
	j HandleCollision	#car intersects player
	noCarCollision:
	addi $t3, $t3, 20
	j CarCollisionCheck
	CarCollisionCheckEnd:
	jr $ra
	HandleCollision:
	lw $t4, isShielded
	bgtz $t4, CarCollisionCheckEnd	#skip collision if shielded
	lw $t1, lives		#load lives
	addi $t1, $t1, -1	#decrease lives
	sw $t1, lives		#store lives
	bltz $t1, GameOver	#out of lives	
	j Reset			#reset level


SpawnStuff:
	la $t0, cars		#load address of cars
	addi $t0, $t0, 20	#skip over player
	li $t1, 0		#counter
	lw $t2, fps	#load fps
	mul $t3, $t2, 3#set $t3 to 3*fps
	mul $t9, $t2, 5#set $t9 to 5*fps
	spawnLaneLoop:
		bgt $t1, 12, spawnLaneLoopEnd	#4 lanes
		
		la $t4, laneTimers	#get lane timers addresss
		add $t4, $t4, $t1	#get cur lane timer address
		lw $t5, 0($t4)		#get cur lane timer value
		addi $t5, $t5, -1	#decrement lane timer
		sw $t5, 0($t4)		#store new lane timer
		
		
		bgez $t5, doneSpawn	#dont spawn unless timer>=3*fps + rng(0,5*fps) (spawn every 3-8 seconds)
		
		li $v0, 42  	#rng from 0 to 5*fps
		li $a0, 0  	#id
		move $a1, $t9  	#max number
		syscall
		add $t3, $t3, $a0 #set $t3 to 3*fps + rng(0, 5*fps) (spawn every 3-8 seconds)	
		sw $t3, 0($t4)	#reset timer to random value
		li $v0, 42  	#rng
		li $a0, 0  	#id
		li $a1, 150  	#max number
		syscall
		addi $t2, $a0, -75 #set $t2 to additional speed		
		li $v0, 42  	#rng
		li $a0, 0  	#id
		li $a1, 16777216  	#max number
		syscall
		move $t3, $a0	#set $t3 to new colour
		
		li $v0, 42  	#rng
		li $a0, 0  	#id
		li $a1, 100  	#max number
		syscall		#a0 has rng for pickups
		
		la $t4, lastCars	#load last cars address into $t4
		add $t4, $t4, $t1	#last car address of cur lane
		lw $t5, 0($t4)		#last car of cur lane value
		lw $t6, enemySpeed	#load enemySpeed
		add $t6, $t6, $t2	#set $t6 to new speed with random factor
		blt $t1, 8, leftSideCars
		sub $t6, $zero, $t6	#negate speed to cars on right side of road
		leftSideCars:
		bgtz $t5, secondCar	#spawn car at second memory location
		#first car
		li $t5, 1	#set $t5 to 1
		sw $t5, 0($t4)	#update last car
		sw $t6, 8($t0)	#set speed
		sw $t3, 16($t0)	#set colour
		li $t3, -8
		sw $t3, 4($t0)	#set y pos to -8
		j doneSpawn
		secondCar:
		sw $zero, 0($t4) 	#update last car
		addi $t0, $t0, 20	#go to second car
		sw $t6, 8($t0)	#set speed
		sw $t3, 16($t0)	#set colour
		li $t3, -8
		sw $t3, 4($t0)	#set y pos to -8
		addi $t0, $t0, -20	#go back inline
		doneSpawn:	
		
		
		addi $t1, $t1, 4	#go next lane
		addi $t0, $t0, 40	#lane's cars
		j spawnLaneLoop
	spawnLaneLoopEnd:
	jr $ra
	
GetPlayerMoveAmt:
	la $t0, cars		#load address of player
	lw $t4, 8($t0)		#load player speed into $t4
	lw $t5, 12($t0)		#load player carry into $t5
	lw $t6, fps		#load fps into $t6
	mul $t6, $t6, 10	#store 10*fps in $t6
	div $t4, $t6		
	mflo $t4		#load quotient(carSpeed, 10*fps) into $t4 (pixels to move)
	mfhi $t7		#load remainder(carSpeed, 10*fps) into $t7(carry). works with negatives
	add $t5, $t5, $t7	#store carryThisUpdate + pastCary in $t5
	sub $t8, $zero, $t5	#set $t8 to negative totalCarry (|totalCarry|)
	blt $t8, $t6, endPlayerCarry	#skip if -totalCarry < 10*fps (run if -totalCarry >= 10*fps)
	add $t5, $t5, $t6	#add 10*fps to totalCarry
	addi $t4, $t4, -1	#subtract 1 to $t4 (pixels to move)
	endPlayerCarry:
	sw $t5, 12($t0)		#set new car carry
	
	sw $t4, playerMoveAmt	#update playerMoveAmt
	jr $ra			#return

MoveAllCars:
	li $t1, 20	#counter
	li $t2, 160	#max counter
	lw $t3, playerMoveAmt	#load playerMoveAmt
	lw $t4, fps	#load fps
	mul $t4, $t4, 10	#store 10*fps in $t4
	moveCarsLoop:
	bgt $t1, $t2, moveCarsLoopEnd
	la $t0, cars
	add $t0, $t0, $t1	#address of cur car
	lw $t5, 4($t0)		#load car y into $t5
	lw $t6, 8($t0)		#load car speed into $t6
	lw $t7, 12($t0)		#load car carry into $t7
	div $t6, $t4
	mflo $t6		#load quotient(carSpeed, 10*fps) into $t6 (pixels to move)
	mfhi $t8		#load remainder(carSpeed, 10*fps) into $t8(carry)
	add $t7, $t7, $t8	#store carryThisUpdate + pastCary in $t7
	bltz $t7, negativeCarCarry	#branch if negative carry
	blt $t7, $t4, endCarCarry	#skip if totalCarry < 10*fps (run if totalCarry >= 10*fps)
	sub $t7, $t7, $t4	#subtract 10*fps from totalCarry
	addi $t6, $t6, 1	#add 1 to $t4 (pixels to move)
	j endCarCarry
	negativeCarCarry:
	sub $t9, $zero, $t7	#set $t9 to negative totalCarry
	blt $t9, $t4, endCarCarry	#skip if -totalCarry < 10*fps (run if -totalCarry >= 10*fps)
	add $t7, $t7, $t4	#add 10*fps to totalCarry
	addi $t6, $t6, -1	#subtract 1 to $t6 (pixels to move)
	endCarCarry:
	sub $t6, $t6, $t3	#subtract playerMoveAmt from ammount to move
	add $t5, $t5, $t6	#change car y based on pixels to move
	sw $t5, 4($t0)		#set new car y
	sw $t7, 12($t0)		#set new car carry
	addi $t1, $t1, 20	#next car
	j moveCarsLoop
	moveCarsLoopEnd:
	jr $ra			#return
	


	
Paint:
	addi $sp, $sp, -4	#shift sp
	sw $ra, 0($sp)		#push sp on stack
	######    DO STUFF    ######
	
	la $s0, paintBuffer	#load paintBufferAddress into $S0
	li $s1, 0x3a3a3a	#load road colour into $s1
	li $s2, 0xe8e8e8	#load white lane divider into $s2
	li $s3, 0xffd800	#load yellow road divider into $s3
	li $s4, 0xfffc59	#load headlight colour into $s4
	li $s5, 0xe51300	#load brakelight colour into $s5
	li $s6, 0x37635e	#load windshield colour into $s6
	jal PaintRoad		#call paint road
	jal PaintCars
	jal PaintProgressBar
	jal PaintShieldBar
	jal PaintLives
	jal PaintBufferToDisplay

	
	######    DO STUFF    ######
	lw $ra, 0($sp)		#pop sp from stack
	addi $sp, $sp, 4	#shift sp
	jr $ra			#return

PaintProgressBar:
	addi $t0, $s0, 8064	#bottom row
	lw $t1, levelProgress
	mul $t1, $t1, 32
	div $t1, $t1, 150	#levelProgress * 32 /1500
	add $t1, $t1, $t0	#max
	addi $t1, $t1, -1
	li $t2, 0x5aff14	#greeen
	paintProgressBarLoop:
	bgt $t0, $t1, paintProgressBarLoopEnd
	sw $t2, 0($t0)
	addi $t0, $t0, 4
	j paintProgressBarLoop
	paintProgressBarLoopEnd:
	jr $ra
	
PaintShieldBar:
	addi $t0, $s0, 7936	#bottom row
	lw $t1, shieldCharge
	mul $t1, $t1, 32
	div $t1, $t1, 250	#levelProgress * 32 /1500
	add $t1, $t1, $t0	#max
	addi $t1, $t1, -1
	li $t2, 0x0026ff	#blue
	paintShieldBarLoop:
	bgt $t0, $t1, paintShieldBarLoopEnd
	sw $t2, 0($t0)
	addi $t0, $t0, 4
	j paintShieldBarLoop
	paintShieldBarLoopEnd:
	jr $ra
PaintLives:
	lw $t0, lives
	li $t1, 0xff0000
	blt $t0, 2, skipSecondLifePaint
	sw $t1, 7820($s0)
	skipSecondLifePaint:
	blt $t0, 1, skipFirstLifePaint
	sw $t1, 7812($s0)
	skipFirstLifePaint:
	jr $ra

PaintRoad:
	addi $sp, $sp, -4	#shift sp
	sw $ra, 0($sp)		#push sp on stack
	######    DO STUFF    ######
	#paint everything grey
	li $t0, 0		#counter
	li $t1, 8188		#max count
	baseRoadLoop:
		bgt $t0, $t1, baseRoadLoopEnd		#end of loop
		add $t2, $s0, $t0	#set $t2 to paintBufferAddress + 4 * loop iteration
		sw $s1, 0($t2)		#paint road pixel
		addi $t0, $t0, 4		#increment by 4
		j baseRoadLoop
	baseRoadLoopEnd:
	#paint lines
	li $t0, 0		#counter
	li $t1, 63		#max count
	li $t2, 28		#left white offset
	li $t3, 60		#left yellow offset
	li $t4, 64		#right yellow offset
	li $t5, 96		#right white offset
	add $t2, $t2, $s0	#make relative to display
	add $t3, $t3, $s0
	add $t4, $t4, $s0
	add $t5, $t5, $s0
	roadLinesLoop:
		bgt $t0, $t1, roadLinesLoopEnd		#end of loop
		sw $s3, 0($t3)		#paint left part of yellow line
		sw $s3, 0($t4)		#paint right part of yellow line
		lw $t6, lineHeight	#load lineHeight into $t6
		sub $t6, $t0, $t6	#set $t6 to iteration(y) - lineHeight
		li $t7, 8		#set $t7 to 6
		div $t6, $t7
		mfhi $t6		#set $t6 to remainder((y - lineHeight) / 6)
		li $t7, 4		#set $t7 to 3
		blt $t6, $t7, skipPaintWhiteLine	#branch if ((y - lineHeight) / 6) > 3
		sw $s2, 0($t2)		#paint left white line
		sw $s2, 0($t5)		#paint right white line
		skipPaintWhiteLine: 
		addi $t0, $t0, 1		#increment by 1 
		addi $t2, $t2, 128		#increment by 32
		addi $t3, $t3, 128		#increment by 32
		addi $t4, $t4, 128		#increment by 32
		addi $t5, $t5, 128		#increment by 32
		j roadLinesLoop
	roadLinesLoopEnd:
	
	
	######    DO STUFF    ######
	lw $ra, 0($sp)		#pop sp from stack
	addi $sp, $sp, 4	#shift sp
	jr $ra			#return
	
PaintBufferToDisplay:
	#paint from buffer
	li $t0, 0		#counter
	li $t1, 8188		#max count
	lw $t2, displayAddress
	paintBufferLoop:
		bgt $t0, $t1, paintBufferLoopEnd		#end of loop
		add $t3, $t2, $t0	#set $t3 to displayAddress + 4 * loop iteration
		add $t4, $s0, $t0	#set $t4 to bufferAddress + 4 * loop iteration
		lw $t5 0($t4)		#set $t5 to pixel's colour in buffer
		sw $t5, 0($t3)		#paint road pixel in display
		addi $t0, $t0, 4	#increment by 4
		j paintBufferLoop
	paintBufferLoopEnd:
	jr $ra

	
PaintCar:		
	lw $t0, 0($sp)		#pop car address from stack
	addi $sp, $sp, 4	#shift sp
	lw $t1, 0($t0)		#load x pos
	lw $t2, 4($t0)		#load y pos
	lw $t3, 16($t0)		#load colour
	sll $t1, $t1, 2		#mult by 4 to word allign
	sll $t2, $t2, 2		#mult by 4 to word allign
	
	li $t4, 0	#counter
	li $t5, 156	#max count 5*8-1
	

	
	paintCarLoop:
	bgt $t4, $t5, paintCarLoopEnd	#branch if all pixels painted
	sll $t6, $t2, 5		#set $t6 to 32*y
	blt $t6, 0, skipCarPixel	#if offscreen, dont paint
	bgt $t6, 8064, skipCarPixel	#if offscreen, dont paint
	add $t6, $t6, $t1	#set $t6 to 32*y + x
	add $t6, $t6, $s0	#set $t6 to 32*y + x + bufferAddress (address of pixel to paint)
	sw $t3, 0($t6)		#paint pixel car colour
	skipCarPixel:
	addi $t1, $t1, 4	#increment x
	addi $t4, $t4, 4	#increment counter
	li $t7, 5
	div $t4, $t7	#divide counter by 5
	mfhi $t7	#$t7 = column mod 5 * 4 = column that was just painted
	bgtz $t7, skipNewLinePaintCar
	addi $t1, $t1, -20	#go back to leftmost coloumn
	addi $t2, $t2, 4	#go down one row
	skipNewLinePaintCar:
	j paintCarLoop
	paintCarLoopEnd:
	
	
	addi $t2, $t2, -32
	sll $t6, $t2, 5		#set $t6 to 32*y
	add $t6, $t6, $t1	#set $t6 to 32*y + x
	add $t7, $t6, $s0	#set $t7 relative to paintbuffer
	la $t9, cars
	beq $t9, $t0, isPlayerCarPaint
	blt $t1, 64, leftSidePaintCar
	isPlayerCarPaint:
	
	#paint headlights
	blt $t6, 0, skipHeadlightPaintCar	#if offscreen, dont paint
	bgt $t6, 8064, skipHeadlightPaintCar	#if offscreen, dont paint
	sw $s4, 0($t7)		#paint left headlight
	sw $s4, 16($t7)		#paint right headlight
	skipHeadlightPaintCar:
	#paint brakeslights
	blt $t6, -896, skipBrakelightPaintCar	#if offscreen, dont paint
	bgt $t6, 7296, skipBrakelightPaintCar	#if offscreen, dont paint
	sw $s5, 900($t7)		#paint left brakelight
	sw $s5, 908($t7)		#paint left brakelight
	skipBrakelightPaintCar:
	#paint windshield
	blt $t6, -256, skipWindshieldPaintCar	#if offscreen, dont paint
	bgt $t6, 7936, skipWindshieldPaintCar	#if offscreen, dont paint
	sw $s6, 260($t7)		#paint left windshield
	sw $s6, 264($t7)		#paint centre windshield
	sw $s6, 268($t7)		#paint right windshield
	skipWindshieldPaintCar:
	jr $ra
	leftSidePaintCar:
	#paint headlights
	blt $t6, -896, skipHeadlightPaintCarLeft	#if offscreen, dont paint
	bgt $t6, 7296, skipHeadlightPaintCarLeft	#if offscreen, dont paint
	sw $s4, 896($t7)		#paint left headlight
	sw $s4, 912($t7)		#paint right headlight
	skipHeadlightPaintCarLeft:
	#paint brakeslights
	blt $t6, 0, skipBrakelightPaintCarLeft	#if offscreen, dont paint
	bgt $t6, 8192, skipBrakelightPaintCarLeft	#if offscreen, dont paint
	sw $s5, 4($t7)		#paint left brakelight
	sw $s5, 12($t7)		#paint left brakelight
	skipBrakelightPaintCarLeft:
	#paint windshield
	blt $t6, -640, skipWindshieldPaintCarLeft	#if offscreen, dont paint
	bgt $t6, 7552, skipWindshieldPaintCarLeft	#if offscreen, dont paint
	sw $s6, 644($t7)		#paint left windshield
	sw $s6, 648($t7)		#paint centre windshield
	sw $s6, 652($t7)		#paint right windshield
	skipWindshieldPaintCarLeft:
	jr $ra
	
	

PaintCars:		#paint all cars
	addi $sp, $sp, -4	#shift sp
	sw $ra, 0($sp)		#push ra on stack
	######    DO STUFF    ######
	li $t0, 0	#counter
	li $t1, 160	#maxCouter
	la $t2, cars	#address of cars
	paintCarsLoop:
		bgt $t0, $t1, paintCarsLoopEnd	#branch if all cars have been painted
		add $t3, $t2, $t0	#set t3 to address of current car
		addi $sp, $sp, -4	#shift sp
		sw $t0, 0($sp)		#push $t0 on stack
		addi $sp, $sp, -4	#shift sp
		sw $t1, 0($sp)		#push $t1 on stack
		addi $sp, $sp, -4	#shift sp
		sw $t2, 0($sp)		#push $t2 on stack
		addi $sp, $sp, -4	#shift sp
		sw $t3, 0($sp)		#push carAddress on stack
		jal PaintCar		#paint the car
		lw $t2, 0($sp)		#pop $t2 off stack
		addi $sp, $sp, 4	#shift sp
		lw $t1, 0($sp)		#pop $t1 off stack
		addi $sp, $sp, 4	#shift sp
		lw $t0, 0($sp)		#pop $t0 off stack
		addi $sp, $sp, 4	#shift sp
		addi $t0, $t0, 20	#increment counter
		j paintCarsLoop		
	paintCarsLoopEnd:
	######    DO STUFF    ######
	lw $ra, 0($sp)		#pop ra from stack
	addi $sp, $sp, 4	#shift sp
	jr $ra			#return

End:



#colour generation algorithm
#generate 1 num from 0-255, 2 num from 20-255
#assign num to rgb randomly
#decrease each rgb value by floor(original value / 10)




 
