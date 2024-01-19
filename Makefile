# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jodufour <jodufour@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/12/27 00:40:53 by jodufour          #+#    #+#              #
#    Updated: 2024/01/18 23:32:23 by jodufour         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

######################################
#              COMMANDS              #
######################################
AS			=	nasm
AR			=	ar rcs
MKDIR		=	mkdir -p
RM			=	rm -rf

#######################################
#               LIBRARY               #
#######################################
NAME		=	libasm.a
NAME_BONUS	=	libasm_bonus.a

#######################################
#             DIRECTORIES             #
#######################################
SRC_DIR		=	src
OBJ_DIR		=	obj
INC_DIR		=	include

######################################
#            SOURCE FILES            #
######################################
SRC = \
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
	}
SRC_BONUS = \
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
OBJ			=	${SRC:.s=.o}
OBJ			:=	${addprefix ${OBJ_DIR}/, ${OBJ}}

OBJ_BONUS	=	${SRC_BONUS:.s=.o}
OBJ_BONUS	:=	${addprefix ${OBJ_DIR}/, ${OBJ_BONUS}}

DEP			=	${OBJ:.o=.d}

#######################################
#                FLAGS                #
#######################################
AFLAGS		=	-f elf64

ifeq (${DEBUG}, 1)
	AFLAGS	+=	-g
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

-include ${DEP}

${OBJ_DIR}/%.o: ${SRC_DIR}/%.s
	@${MKDIR} ${@D}
	${AS} ${AFLAGS} -MF ${@:.o=.d} $< ${OUTPUT_OPTION}

clean:
	${RM} ${OBJ_DIR} vgcore.*

fclean: clean
	${RM} ${NAME} ${NAME_BONUS}

re: clean all

fre: fclean all