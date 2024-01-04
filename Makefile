# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jodufour <jodufour@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/12/27 00:40:53 by jodufour          #+#    #+#              #
#    Updated: 2024/01/03 17:00:48 by jodufour         ###   ########.fr        #
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
				ft_atoi_base_bonus.s		\
				ft_list_remove_if_bonus.s	\
				ft_list_push_front_bonus.s	\
				ft_list_size_bonus.s		\
				ft_list_sort_bonus.s

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
.PHONY: bonus all clean fclean re fre

${NAME}: ${OBJ}
	${AR} $@ $^

${NAME_BONUS}: ${OBJ_BONUS}
	${AR} $@ $^

bonus: ${NAME_BONUS}

all: ${NAME} ${NAME_BONUS}

-include ${DEP}

${OBJ_DIR}/%.o: ${SRC_DIR}/%.s
	@${MKDIR} ${@D}
	${AS} ${AFLAGS} -MF ${@:.o=.d} $< ${OUTPUT_OPTION}

clean:
	${RM} ${OBJ_DIR} ${NAME} vgcore.*

fclean:
	${RM} ${OBJ_DIR} ${NAME} vgcore.*

re: clean all

fre: fclean all