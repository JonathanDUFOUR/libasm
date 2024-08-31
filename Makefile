# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jodufour <jodufour@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/12/27 00:40:53 by jodufour          #+#    #+#              #
#    Updated: 2024/08/30 17:31:31 by jodufour         ###   ########.fr        #
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

######################################
#            SOURCE FILES            #
######################################
SRC := \
	${addsuffix .s, \
		${addprefix ft_, \
			${addprefix memcpy/, \
				dsta_srcu \
				dstu_srca \
				dstu_srcu \
			} \
			${addprefix strcmp/, \
				s0a_s1u \
				s0u_s1a \
				s0u_s1u \
			} \
			${addprefix strcpy/, \
				dsta_srcu \
				dstu_srca \
				dstu_srcu \
			} \
			${addprefix strlen/, \
				sa \
				su \
			} \
			memcpy \
			read \
			strcmp \
			strcpy \
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
	-I ${SRC_DIR}

ifeq (${DEBUG}, 1)
	AFLAGS += -g
endif

#######################################
#                RULES                #
#######################################
.PHONY: all
all: ${NAME} ${NAME_BONUS}

.PHONY: bonus
bonus: ${NAME_BONUS}

${NAME}: ${OBJ}
	${AR} $@ $^

${NAME_BONUS}: ${OBJ_BONUS}
	${AR} $@ $^
	${AR} ${NAME} $^

-include ${DEP} ${DEP_BONUS}

${OBJ_DIR}/%.o: ${SRC_DIR}/%.s
	@${MKDIR} ${@D}
	${AS} ${AFLAGS} -MD ${@:.o=.d} $< ${OUTPUT_OPTION}

.PHONY: clean
clean:
	${RM} ${OBJ_DIR} vgcore.*

.PHONY: fclean
fclean: clean
	${RM} ${NAME} ${NAME_BONUS}

.PHONY: re
re: clean all

.PHONY: fre
fre: fclean all
