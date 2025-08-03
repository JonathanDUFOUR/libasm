# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jodufour <jodufour@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/12/27 00:40:53 by jodufour          #+#    #+#              #
#    Updated: 2025/08/02 07:21:38 by jodufour         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

######################################
#              COMMANDS              #
######################################
 NASM := ${shell which nasm}
   AR := ${shell which ar} rcs
MKDIR := ${shell which mkdir} -p
   RM := ${shell which rm} -rf

#######################################
#               LIBRARY               #
#######################################
      NAME := libasm.a
BONUS_NAME := libasm_bonus.a

#######################################
#             DIRECTORIES             #
#######################################
SRC_DIR := src
OBJ_DIR := obj
PRV_DIR := private

######################################
#            SOURCE FILES            #
######################################
SRC := \
	${addsuffix .nasm, \
		${addprefix ft_, \
			${addsuffix /core, \
				memcmp \
				strlen \
				strcmp \
			} \
			memcpy \
			read \
			strcpy \
			strdup \
			write \
		} \
	} \

BONUS_SRC := \
	${addsuffix .nasm, \
		${addprefix ft_, \
			atoi_base \
			${addprefix list_, \
				remove_if \
				push_front \
				size \
				sort \
			} \
		} \
	} \

######################################
#            OBJECT FILES            #
######################################
OBJ := ${addprefix ${OBJ_DIR}/, ${SRC:.nasm=.o}}
DEP := ${OBJ:.o=.d}

BONUS_OBJ := ${addprefix ${OBJ_DIR}/, ${BONUS_SRC:.nasm=.o}}
BONUS_DEP := ${BONUS_OBJ:.o=.d}

#######################################
#                FLAGS                #
#######################################
NASM_FLAGS = \
	-f elf64 \
	-werror \
	-I ${<D}/ \
	-I ${PRV_DIR}/ \

ifeq (${DEBUG}, 1)
	NASM_FLAGS += -g
endif

#######################################
#                RULES                #
#######################################
.PHONY: all
all: ${NAME} ${BONUS_NAME}

.PHONY: bonus
bonus: ${BONUS_NAME}

${NAME}: ${OBJ}
	${AR} $@ $^

${BONUS_NAME}: ${BONUS_OBJ}
	${AR} $@ $^
	${AR} ${NAME} $^

-include ${DEP} ${BONUS_DEP}

${OBJ_DIR}/%.o: ${SRC_DIR}/%.nasm
	@${MKDIR} ${@D}
	${strip ${NASM} ${NASM_FLAGS} -M -MF ${@:.o=.d} $< ${OUTPUT_OPTION}}
	${strip ${NASM} ${NASM_FLAGS} $< ${OUTPUT_OPTION}}

.PHONY: clean
clean:
	${RM} ${OBJ_DIR} vgcore.*

.PHONY: fclean
fclean: clean
	${RM} ${NAME} ${BONUS_NAME}

.PHONY: re
re: clean all

.PHONY: fre
fre: fclean all
