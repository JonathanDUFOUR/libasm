/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_asm.h                                           :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: jodufour <jodufour@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2024/01/03 16:23:07 by jodufour          #+#    #+#             */
/*   Updated: 2024/01/03 16:32:34 by jodufour         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef FT_ASM_H
# define FT_ASM_H

# include <sys/types.h>

int ft_strcmp(char const *s0, char const *s1) __attribute__((nonnull));

char *ft_strcpy(char *dst, char const *src) __attribute__((nonnull));
char *ft_strdup(char const *s) __attribute__((nonnull));

size_t ft_strlen(char const *s) __attribute__((nonnull));

ssize_t ft_read(int fd, void *buf, size_t count) __attribute__((nonnull));
ssize_t ft_write(int fd, void const *buf, size_t count) __attribute__((nonnull));

#endif