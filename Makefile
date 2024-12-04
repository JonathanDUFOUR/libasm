# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jodufour <jodufour@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/12/27 00:40:53 by jodufour          #+#    #+#              #
#    Updated: 2024/12/04 17:36:45 by jodufour         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

######################################
#              COMMANDS              #
######################################
   AS := ${shell which nasm}
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

######################################
#            SOURCE FILES            #
######################################
SRC := \
	${addsuffix .s, \
		${addprefix ft_, \
			memcpy \
			read \
			strcmp \
			strcpy \
			strdup \
			strlen \
			write \
		} \
	} \

BONUS_SRC := \
	${addsuffix .s, \
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
OBJ := ${addprefix ${OBJ_DIR}/, ${SRC:.s=.o}}
DEP := ${OBJ:.o=.d}

BONUS_OBJ := ${addprefix ${OBJ_DIR}/, ${BONUS_SRC:.s=.o}}
BONUS_DEP := ${BONUS_OBJ:.o=.d}

#######################################
#                FLAGS                #
#######################################
AFLAGS := \
	-f elf64 \
	-werror \
	-I ${SRC_DIR} \

ifeq (${DEBUG}, 1)
	AFLAGS += -g
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

${OBJ_DIR}/%.o: ${SRC_DIR}/%.s
	@${MKDIR} ${@D}
	${strip ${AS} ${AFLAGS} -MD ${@:.o=.d} $< ${OUTPUT_OPTION}}

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
