# main.asm
# Ponto de entrada para o Sistema de Busca OPO

# Inclui outros módulos
# Nota: graph.asm inclui readfile.asm

.include "graph.asm"
.include "ui.asm"
.include "search.asm"
.include "add_record.asm"
.include "writefile.asm"

.text
.globl main

main:
    # Imprime Cabeçalho da Aplicação
    jal print_header

main_loop:
    # Imprime Menu
    jal print_menu
    
    # Obtém Escolha do Usuário
    jal get_user_choice
    move $s0, $v0       # Salva escolha em $s0

    # Trata Escolha
    li $t0, 1
    beq $s0, $t0, do_load_data
    
    li $t0, 2
    beq $s0, $t0, do_visualize_db
    
    li $t0, 3
    beq $s0, $t0, do_add_record
    
    li $t0, 4
    beq $s0, $t0, do_visualize_graph
    
    li $t0, 5
    beq $s0, $t0, do_search
    
    li $t0, 6
    beq $s0, $t0, do_exit
    
    # Opção Inválida
    jal print_error_msg
    j main_loop

do_load_data:
    # 1. Lê dados do arquivo
    # readfile está definido em readfile.asm
    jal readfile
    
    # 2. Inicializa estrutura do grafo
    # init_graph está definido em graph.asm
    jal init_graph
    
    # Opcional: Imprimir mensagem de sucesso (poderia ser adicionado em ui.asm)
    j main_loop

    j main_loop

do_visualize_db:
    jal visualize_database
    j main_loop

do_add_record:
    jal add_new_record
    j main_loop

do_visualize_graph:
    jal visualize_graph
    j main_loop

do_search:
    jal buscar_orgao_proximo
    j main_loop

do_exit:
    jal print_exit_msg
    
    # Syscall de Saída
    li $v0, 10
    syscall
