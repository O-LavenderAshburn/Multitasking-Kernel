
.equ    pcb_link, 0
.equ    pcb_reg1, 1
.equ    pcb_reg2, 2
.equ    pcb_reg3, 3
.equ    pcb_reg4, 4
.equ    pcb_reg5, 5
.equ    pcb_reg6, 6
.equ    pcb_reg7, 7
.equ    pcb_reg8, 8
.equ    pcb_reg9, 9
.equ    pcb_reg10, 10
.equ    pcb_reg11, 11
.equ    pcb_reg12, 12
.equ    pcb_reg13, 13
.equ    pcb_sp, 14
.equ    pcb_ra, 15
.equ    pcb_ear, 16
.equ    pcb_cctrl, 17
.equ    pcb_isGame,18

.text
.global main

main:

subui $sp,$sp,1
lw $ra, 0($sp)
la $1,exitTask
addi $ra,$1,0


#movsg $3,$cctrl #get cctrl
#ori $3,$3,0x4A #enable timer
#movgs $cctrl,$3 #set cctrl

# UPDATE CPU CONTROL REGISTER
# Get the current value of the CPU control register
movsg $1, $cctrl
# Enable the IRQ2 bit and interrupts
ori $1, $1, 74
# Update the control register with the new value
movgs $cctrl, $1


#store old vector
movsg $3,$evec
sw $3, old_vector($0)

#load new handler
la $3, handler
movgs $evec,$3


# set up idle task
        la $1, idle_pcb
#link idleTask to itself
        sw $1, pcb_link($1)
        la $2, idle
#set pointer to itself
        sw $2,pcb_ear($1)
#set cctrl
        addi $2, $0, 0x4d
        sw $2,pcb_cctrl($1)


addi $6,$0,0
addi $7,$0,1
#set the is game value to 0 if not a game

la $1, task1_pcb
sw $6,pcb_isGame($1)

la $1, task2_pcb
sw $6,pcb_isGame($1)

la $1, task3_pcb
sw $7,pcb_isGame($1)



#get cctrl value
addi $5,$0,0x4d
#load address of task pcb's
la $1, task1_pcb
la $2, task2_pcb
sw $ra,pcb_ra($1)
#task 1
#set the link
sw $2,pcb_link($1)
#setup stack
la $3,task1_stack
sw $3,pcb_sp($1)
#setup ear feild
la $3,serial_main
sw $3,pcb_ear($1)
#set cctrl
sw $5,pcb_cctrl($1)

la $1,task3_pcb
#task 2
sw $1,pcb_link($2)
#stack pointer
la $3,task2_stack
sw $3,pcb_sp($2)
sw $ra,pcb_ra($2)

#earFeild
la $3,parallel_main
sw $3,pcb_ear($2)
#cctrl feild
sw $5, pcb_cctrl($2)


la $1, task3_pcb
la $2, task1_pcb

sw $ra,pcb_ra($1)

#gametask
sw $2,pcb_link($1)
#setup stack
la $3,task3_stack
sw $3,pcb_sp($1)
la $3,gameSelect_main
sw $3,pcb_ear($1)
sw $5,pcb_cctrl($1)


#set timer to 100 interupts per second
addi $2,$0,24
sw $2, 0x72001($0)

addi $3,$0,3
sw $3, 0x72000($0)

#start first task
sw $1, current_task($0)
j load_context

handler:
movsg $13,$estat
andi $13,$13, 0xffB5
beqz $13,timerHandler
j default_handler

#handle exception
timerHandler:
lw $13,counter($0)
addi $13,$13,1
sw $13,counter($0)
sw $0, 0x72003($0)
lw $13,timeSlice($0)
subi $13,$13,1
sw $13,timeSlice($0)
beqz $13,Dispatcher
rfe


default_handler:
lw $13, old_vector($0)
jr $13

Dispatcher:
lw $13,current_task($0)
sw $1,  pcb_reg1($13)
sw $2,  pcb_reg2($13)
sw $3,  pcb_reg3($13)
sw $4,  pcb_reg4($13)
sw $5,  pcb_reg5($13)
sw $6,  pcb_reg6($13)
sw $7,  pcb_reg7($13)
sw $8,  pcb_reg8($13)
sw $9,  pcb_reg9($13)
sw $10, pcb_reg10($13)
sw $11, pcb_reg11($13)
sw $12, pcb_reg12($13)
sw $ra, pcb_ra($13)
sw $sp, pcb_sp($13)

#save the old $13 to its pcb
movsg $1,$ers
sw $1,  pcb_reg13($13)
#save $ear
movsg $1,  $ear
sw $1, pcb_ear($13)
#save the cctrl
movsg $1,$cctrl
sw $1,  pcb_cctrl($13)

#schedule next task
lw $1, pcb_link($13)
sw $1, current_task($0)

#Restore context
load_context:
addi $13,$0,2
sw $13,timeSlice($0)


#load the pcb of the current context
lw  $13,    current_task($0)

lw $1,pcb_reg13($13)
movgs $ers,$1
#restore $ear
lw $1, pcb_ear($13)
movgs $ear,$1
#restore $cctrl
lw $1, pcb_cctrl($13)
movgs $cctrl,$1

lw $1,  pcb_reg1($13)
lw $2,  pcb_reg2($13)
lw $3,  pcb_reg3($13)
lw $4,  pcb_reg4($13)
lw $5,  pcb_reg5($13)
lw $6,  pcb_reg6($13)
lw $7,  pcb_reg7($13)
lw $8,  pcb_reg8($13)
lw $9,  pcb_reg9($13)
lw $10, pcb_reg10($13)
lw $11, pcb_reg11($13)
lw $12, pcb_reg12($13)
lw $ra, pcb_ra($13)
lw $sp, pcb_sp($13)


lw $13,pcb_isGame($13)
beqz $13,return
addi $13,$0,100
sw $13,timeSlice($0)
rfe

return:
rfe
exitTask:
#load the current task
lw  $1,current_task($0)


#laod the link of the current task
lw $2,pcb_link($1)
#laod the link of the next task
lw $3,pcb_link($2)

seq $4,$1,$2
bnez $4,setIdle

seq $4,$1,$3
bnez $4,exitSecondTask

# if not overwrite the old link
sw $2,pcb_link($3)
sw $2,current_task($0)
j load_context

exitSecondTask:
sw $2,pcb_link($2)
sw $2,current_task($0)

j load_context


setIdle:
la $1,idle_pcb
sw $1,current_task($0)
j load_context

idle:
j idle


.bss


timeSlice:
           .word
current_task:
            .word
old_vector:
            .word
task1_pcb:
        .space 19
task2_pcb:
        .space 19
task3_pcb:
        .space 19
idle_pcb:
        .space 19

        .space 100
task1_stack:
        .space 100
task2_stack:
        .space 100
task3_stack:








