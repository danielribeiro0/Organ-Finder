# ui.asm
# Interface baseada em texto e módulo de visualização

.data
    # Strings para UI
    header_str:     .asciiz "\n################################\n#      SISTEMA DE BUSCA OPO    #\n################################\n"
    menu_str:       .asciiz "\n=== MENU PRINCIPAL ===\n1. Carregar Dados (do arquivo)\n2. Visualizar Grafo\n3. Buscar Orgao\n4. Sair\n\nDigite sua escolha: "
    invalid_opt:    .asciiz "\nOpcao invalida! Por favor tente novamente.\n"
    bye_str:        .asciiz "\nSaindo do sistema... Adeus!\n"
    
    # Strings para Visualização
    vis_header:     .asciiz "\n=== VISUALIZACAO DO GRAFO ===\n"
    node_prefix:    .asciiz "No "
    arrow_str:      .asciiz " -> "
    dist_open:      .asciiz " [Distancia: "
    dist_close:     .asciiz " km]\n"
    no_conn_str:    .asciiz "  (Sem conexoes)\n"
    
    # Strings para Busca (Placeholder)
    search_prompt:  .asciiz "\n[Recurso de Busca] Digite o Nome do Orgao: "
    search_res_stub:.asciiz "\nFuncionalidade de busca ainda nao implementada.\n"

.text
.globl print_header
.globl print_menu
.globl get_user_choice
.globl visualize_graph
.globl print_search_stub
.globl print_error_msg
.globl print_exit_msg

# -----------------------------------------------------------------------------
# Função: print_header
# Descrição: Imprime o cabeçalho da aplicação
# -----------------------------------------------------------------------------
print_header:
    li $v0, 4
    la $a0, header_str
    syscall
    jr $ra

# -----------------------------------------------------------------------------
# Função: print_menu
# Descrição: Imprime as opções do menu principal
# -----------------------------------------------------------------------------
print_menu:
    li $v0, 4
    la $a0, menu_str
    syscall
    jr $ra

# -----------------------------------------------------------------------------
# Função: get_user_choice
# Descrição: Lê um inteiro do usuário
# Retorna: $v0 = escolha do usuário (inteiro)
# -----------------------------------------------------------------------------
get_user_choice:
    li $v0, 5
    syscall
    
    # Se leu 0, pode ser erro de input (char não numérico).
    # Vamos limpar o buffer até o \n para evitar loop infinito.
    # Nota: 0 também pode ser uma escolha válida se o menu tiver opção 0, 
    # mas aqui as opções são 1-4.
    bnez $v0, guc_done
    
    # Limpa buffer (consome até \n)
    move $t0, $v0       # salva o 0 (se for válido, retorna 0 e main trata como inválido)
    
guc_clean_loop:
    li $v0, 12          # read_char
    syscall
    li $t1, 10          # \n
    beq $v0, $t1, guc_restored
    j guc_clean_loop
    
guc_restored:
    move $v0, $t0       # restaura 0

guc_done:
    jr $ra

# -----------------------------------------------------------------------------
# Função: print_error_msg
# Descrição: Imprime mensagem de opção inválida
# -----------------------------------------------------------------------------
print_error_msg:
    li $v0, 4
    la $a0, invalid_opt
    syscall
    jr $ra

# -----------------------------------------------------------------------------
# Função: print_exit_msg
# Descrição: Imprime mensagem de saída
# -----------------------------------------------------------------------------
print_exit_msg:
    li $v0, 4
    la $a0, bye_str
    syscall
    jr $ra

# -----------------------------------------------------------------------------
# Função: print_search_stub
# Descrição: Placeholder para funcionalidade de busca
# -----------------------------------------------------------------------------
print_search_stub:
    li $v0, 4
    la $a0, search_res_stub
    syscall
    jr $ra

# -----------------------------------------------------------------------------
# Função: visualize_graph
# Descrição: Itera pela matriz de adjacência e imprime conexões
# -----------------------------------------------------------------------------
visualize_graph:
    addi $sp, $sp, -12
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)        # i (linha / nó origem)
    sw   $s1, 8($sp)        # j (coluna / nó destino)

    li $v0, 4
    la $a0, vis_header
    syscall

    # Carrega número de entidades
    lw $t0, num_entities
    blez $t0, vis_end       # Se 0 entidades, nada para mostrar

    li $s0, 0               # i = 0

vis_row_loop:
    lw $t0, num_entities
    bge $s0, $t0, vis_done  # se i >= num_entities, pare

    # Verifica se o nó tem conexões para imprimir (otimização opcional,
    # mas aqui vamos apenas imprimir "No X:" e depois listar conexões)
    
    # Imprime "No X"
    li $v0, 4
    la $a0, node_prefix
    syscall
    
    li $v0, 1
    move $a0, $s0
    syscall
    
    li $v0, 11      # imprime char
    li $a0, 58      # ':'
    syscall
    li $a0, 10      # '\n'
    syscall

    li $s1, 0       # j = 0
    li $t9, 0       # contador de conexões para este nó

vis_col_loop:
    lw $t0, num_entities
    bge $s1, $t0, vis_col_done

    # Calcula endereço de adj_matrix[i][j]
    # Endereço = base + (i * MAX_ENTITIES + j) * 4
    # MAX_ENTITIES é 50 (definido em graph.asm, assumimos que combina)
    li  $t2, 50             
    mul $t3, $s0, $t2       # i * 50
    add $t3, $t3, $s1       # + j
    sll $t3, $t3, 2         # * 4
    
    la  $t4, adj_matrix
    add $t4, $t4, $t3
    lw  $t5, 0($t4)         # Carrega peso

    # Se peso == 0, sem conexão
    beqz $t5, vis_next_col

    # Imprime conexão: " -> No Y [Distancia: W km]"
    li $v0, 4
    la $a0, arrow_str
    syscall
    
    li $v0, 4
    la $a0, node_prefix
    syscall
    
    li $v0, 1
    move $a0, $s1   # ID do Nó (j)
    syscall
    
    li $v0, 4
    la $a0, dist_open
    syscall
    
    li $v0, 1
    move $a0, $t5   # Peso
    syscall
    
    li $v0, 4
    la $a0, dist_close
    syscall
    
    addi $t9, $t9, 1    # incrementa contador de conexões

vis_next_col:
    addi $s1, $s1, 1
    j vis_col_loop

vis_col_done:
    # Se nenhuma conexão encontrada para este nó
    bnez $t9, vis_next_row
    li $v0, 4
    la $a0, no_conn_str
    syscall

vis_next_row:
    addi $s0, $s0, 1
    j vis_row_loop

vis_done:
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    addi $sp, $sp, 12
    jr   $ra

vis_end:
    lw   $ra, 0($sp)
    addi $sp, $sp, 12
    jr   $ra
