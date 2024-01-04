/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_asm_bonus.h                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: jodufour <jodufour@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2024/01/03 16:33:13 by jodufour          #+#    #+#             */
/*   Updated: 2024/01/03 16:58:19 by jodufour         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef FT_ASM_BONUS_H
# define FT_ASM_BONUS_H

typedef struct s_list	t_list;
typedef int				(*fn_cmp)(void *, void *);
typedef void			(*fn_free)(void *);

struct s_list {
	void	*data;
	t_list	*next;
};

void ft_list_push_front(t_list **list, void *data)
	__attribute__((nonnull));
void ft_list_remove_if( t_list **list, void *data_ref, fn_cmp cmp, fn_free free)
	__attribute__((nonnull));
void ft_list_sort(t_list **list, fn_cmp cmp)
	__attribute__((nonnull));

int ft_list_size(t_list *list)
	__attribute__((nonnull));

#endif