# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jodufour <jodufour@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/12/27 00:40:53 by jodufour          #+#    #+#              #
#    Updated: 2023/12/30 05:51:28 by jodufour         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

######################################
#              COMMANDS              #
######################################
AS		=	nasm
LINK	=	ar rcs
MKDIR	=	mkdir -p
RM		=	rm -rf

#######################################
#               LIBRARY               #
#######################################
NAME	=	libasm.a

#######################################
#             DIRECTORIES             #
#######################################
SRC_DIR	=	src
OBJ_DIR	=	obj
PRV_DIR	=	private

######################################
#            SOURCE FILES            #
######################################
SRC		=	\
			ft_read.s	\
			ft_strlen.s

######################################
#            OBJECT FILES            #
######################################
OBJ		=	${SRC:.s=.o}
OBJ		:=	${addprefix ${OBJ_DIR}/, ${OBJ}}

DEP		=	${OBJ:.o=.d}

#######################################
#                FLAGS                #
#######################################
AFLAGS	=	-f elf64

ifeq (${DEBUG}, 1)
	AFLAGS	+=	-g
endif

#######################################
#                RULES                #
#######################################
${NAME}: ${OBJ}
	${LINK} $@ $^

all: ${NAME}

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

.PHONY: all clean fclean re fre
