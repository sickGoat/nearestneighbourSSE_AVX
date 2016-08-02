################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
ASM_SRCS += \
../centroide.asm \
../dist.asm \
../nearestvoren.asm \
../nn.asm \
../nnClass.asm 

C_SRCS += \
../main.c 

OBJS += \
./centroide.o \
./dist.o \
./main.o \
./nearestvoren.o \
./nn.o \
./nnClass.o 

C_DEPS += \
./main.d 


# Each subdirectory must supply rules for building sources it contributes
%.o: ../%.asm
	@echo 'Building file: $<'
	@echo 'Invoking: GCC Assembler'
	nasm -f elf64 -F dwarf  -g  -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

%.o: ../%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler'
	gcc  -O0  -m64 -mavx -lm -g -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


