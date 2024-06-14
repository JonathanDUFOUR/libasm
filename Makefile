# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jodufour <jodufour@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/12/27 00:40:53 by jodufour          #+#    #+#              #
#    Updated: 2024/06/14 11:51:24 by jodufour         ###   ########.fr        #
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
NAME_BONUS := libasm_bonus.a

#######################################
#             DIRECTORIES             #
#######################################
  SRC_DIR := src
  OBJ_DIR := obj
MACRO_DIR := ${SRC_DIR}/macro

######################################
#            SOURCE FILES            #
######################################
SRC := \
	${addsuffix .s, \
		${addprefix ft_, \
			memcpy \
			memcpy_alt \
			read \
			strcmp \
			strcpy \
			strcpy_alt \
			strdup \
			strlen \
			write \
		} \
	}

SRC_BONUS := \
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
	}

######################################
#            OBJECT FILES            #
######################################
OBJ := ${addprefix ${OBJ_DIR}/, ${SRC:.s=.o}}
DEP := ${OBJ:.o=.d}

OBJ_BONUS := ${addprefix ${OBJ_DIR}/, ${SRC_BONUS:.s=.o}}
DEP_BONUS := ${OBJ_BONUS:.o=.d}

#######################################
#                FLAGS                #
#######################################
AFLAGS := \
	-f elf64 \
	-werror \
	-I ${MACRO_DIR}

ifeq (${DEBUG}, 1)
	AFLAGS += -g
endif

#######################################
#                RULES                #
#######################################
.PHONY: all bonus clean fclean re fre

${NAME}: ${OBJ}
	${AR} $@ $^

${NAME_BONUS}: ${OBJ_BONUS}
	${AR} $@ $^
	${AR} ${NAME} $^

all: ${NAME} ${NAME_BONUS}

bonus: ${NAME_BONUS}

-include ${DEP} ${DEP_BONUS}

${OBJ_DIR}/%.o: ${SRC_DIR}/%.s
	@${MKDIR} ${@D}
	${AS} ${AFLAGS} -MF ${@:.o=.d} $< ${OUTPUT_OPTION}

clean:
	${RM} ${OBJ_DIR} vgcore.*

fclean: clean
	${RM} ${NAME} ${NAME_BONUS}

re: clean all

fre: fclean all
