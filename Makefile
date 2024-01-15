# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jodufour <jodufour@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/12/27 00:40:53 by jodufour          #+#    #+#              #
#    Updated: 2024/01/15 14:52:20 by jodufour         ###   ########.fr        #
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
SRC			=	\
				ft_read.s	\
				ft_strcmp.s	\
				ft_strcpy.s	\
				ft_strdup.s	\
				ft_strlen.s	\
				ft_write.s
SRC_BONUS	=	\
				ft_atoi_base.s			\
				ft_list_remove_if.s		\
				ft_list_push_front.s	\
				ft_list_size.s			\
				ft_list_sort.s

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
	${RM} ${OBJ_DIR} ${NAME} vgcore.*

fclean: clean

re: clean all

fre: fclean all