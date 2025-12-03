# search.asm
# Módulo de Busca de Órgãos usando Algoritmo de Dijkstra
# Encontra o doador mais próximo que possui o órgão solicitado.

.data
    # Arrays auxiliares para Dijkstra
    .align 2
    dist:           .space 200      # 50 words (distância mínima)
    visited:        .space 50       # 50 bytes (visitado: 0 ou 1)
    
    # Constantes
    .align 2
    INFINITY:       .word 999999    # Valor para infinito
    
    # Strings de UI para busca
    msg_enter_node: .asciiz "\nDigite o ID do seu no (0-49): "
    msg_enter_organ:.asciiz "Digite o nome do orgao desejado: "
    msg_searching:  .asciiz "\nBuscando doador mais proximo...\n"
    msg_found:      .asciiz "\n=== DOADOR ENCONTRADO ===\n"
    msg_name:       .asciiz "Nome: "
    msg_city:       .asciiz "Cidade: "
    msg_distance:   .asciiz "Distancia: "
    msg_km:         .asciiz " km\n"
    msg_not_found:  .asciiz "\nNenhum doador encontrado com este orgao acessivel.\n"
    
    # Buffer para entrada do órgão
    search_organ:   .space 64

.text
.globl buscar_orgao_proximo

# -----------------------------------------------------------------------------
# Função: buscar_orgao_proximo
# Descrição: Pede inputs e executa a busca
# -----------------------------------------------------------------------------
buscar_orgao_proximo:
    addi $sp, $sp, -24      # Aumentar stack para salvar $s3, $s4
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)        # ID do nó de origem
    sw   $s1, 8($sp)        # ID do melhor candidato
    sw   $s2, 12($sp)       # Menor distância encontrada
    sw   $s3, 16($sp)       # Loop counter i
    sw   $s4, 20($sp)       # num_entities

    # 1. Pedir ID do nó de origem
    li   $v0, 4
    la   $a0, msg_enter_node
    syscall
    
    li   $v0, 5
    syscall
    move $s0, $v0           # $s0 = start_node

    # Validação simples (0 <= id < num_entities)
    lw   $t0, num_entities
    bge  $s0, $t0, search_invalid_node
    bltz $s0, search_invalid_node
    
    # 2. Pedir Nome do Órgão
    li   $v0, 4
    la   $a0, msg_enter_organ
    syscall
    
read_organ_loop:
    # Ler string
    la   $a0, search_organ
    li   $a1, 63
    li   $v0, 8             # read_string
    syscall
    
    # Verifica se leu apenas \n ou \r (linha vazia)
    la   $t0, search_organ
    lb   $t1, 0($t0)
    
    li   $t2, 10            # \n
    beq  $t1, $t2, read_organ_loop
    
    li   $t2, 13            # \r
    beq  $t1, $t2, read_organ_loop
    
    beqz $t1, read_organ_loop # string vazia

    # Remover \n do final da string lida
    la   $a0, search_organ
    jal  remove_newline

    li   $v0, 4
    la   $a0, msg_searching
    syscall

    # 3. Executar Dijkstra
    move $a0, $s0           # arg0 = start_node
    jal  run_dijkstra
    
    # 4. Encontrar melhor candidato
    # Itera por todos os nós, verifica se tem o órgão e pega o de menor dist
    
    li   $s1, -1            # Melhor candidato (inicialmente nenhum)
    lw   $s2, INFINITY      # Menor distância (inicialmente inf)
    
    li   $s3, 0             # i = 0 ($s3)
    lw   $s4, num_entities  # limit ($s4)

find_best_loop:
    bge  $s3, $s4, find_best_done
    
    # Verifica distância (se for infinito, não é alcançável)
    la   $t2, dist
    sll  $t3, $s3, 2        # i * 4
    add  $t2, $t2, $t3
    lw   $t4, 0($t2)        # dist[i]
    
    lw   $t5, INFINITY
    bge  $t4, $t5, next_candidate   # Se inalcançável, pula
    
    # Verifica se tem o órgão
    # ent_organs[i] contém a lista de órgãos
    la   $t6, ent_organs
    sll  $t7, $s3, 7        # i * 128
    add  $t6, $t6, $t7      # Endereço da string de órgãos do nó i
    
    move $a0, $t6           # Haystack (lista de órgãos do doador)
    la   $a1, search_organ  # Needle (órgão buscado)
    jal  str_contains       # Retorna 1 se contém, 0 se não
    
    beqz $v0, next_candidate
    
    # Recarregar distância pois str_contains pode ter sujado $t4
    la   $t2, dist
    sll  $t3, $s3, 2
    add  $t2, $t2, $t3
    lw   $t4, 0($t2)        # dist[i]
    
    # Tem o órgão e é alcançável. Verifica se é o mais próximo.
    bge  $t4, $s2, next_candidate
    
    # Novo melhor candidato!
    move $s1, $s3           # Salva ID
    move $s2, $t4           # Salva Distância
    
next_candidate:
    addi $s3, $s3, 1        # i++
    j    find_best_loop

find_best_done:
    # 5. Mostrar Resultado
    li   $t0, -1
    beq  $s1, $t0, show_not_found
    
    # Encontrou!
    li   $v0, 4
    la   $a0, msg_found
    syscall
    
    # Nome
    li   $v0, 4
    la   $a0, msg_name
    syscall
    
    la   $t0, ent_name
    sll  $t1, $s1, 6        # id * 64
    add  $a0, $t0, $t1
    li   $v0, 4
    syscall
    
    li   $v0, 11
    li   $a0, 10            # \n
    syscall
    
    # Cidade
    li   $v0, 4
    la   $a0, msg_city
    syscall
    
    la   $t0, ent_city
    sll  $t1, $s1, 6        # id * 64
    add  $a0, $t0, $t1
    li   $v0, 4
    syscall
    
    li   $v0, 11
    li   $a0, 10            # \n
    syscall
    
    # Distância
    li   $v0, 4
    la   $a0, msg_distance
    syscall
    
    li   $v0, 1
    move $a0, $s2
    syscall
    
    li   $v0, 4
    la   $a0, msg_km
    syscall
    
    j    search_end

show_not_found:
    li   $v0, 4
    la   $a0, msg_not_found
    syscall
    j    search_end

search_invalid_node:
    li   $v0, 4
    la   $a0, msg_not_found # Reutilizando msg para simplificar, ou poderia criar msg de erro
    syscall

search_end:
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    lw   $s3, 16($sp)
    lw   $s4, 20($sp)
    addi $sp, $sp, 24
    jr   $ra

# Entrada: $a0 = start_node
# -----------------------------------------------------------------------------
run_dijkstra:
    addi $sp, $sp, -20
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)        # start_node
    sw   $s1, 8($sp)        # count (nós visitados)
    sw   $s2, 12($sp)       # num_entities
    sw   $s3, 16($sp)       # u (nó atual selecionado)

    move $s0, $a0
    lw   $s2, num_entities
    
    # 1. Inicialização
    # dist[] = INFINITY, visited[] = 0
    li   $t0, 0             # i = 0
    lw   $t1, INFINITY
    la   $t2, dist
    la   $t3, visited
    
dijkstra_init_loop:
    bge  $t0, $s2, dijkstra_init_done
    
    sll  $t4, $t0, 2        # i * 4
    add  $t5, $t2, $t4
    sw   $t1, 0($t5)        # dist[i] = INF
    
    add  $t5, $t3, $t0
    sb   $zero, 0($t5)      # visited[i] = 0
    
    addi $t0, $t0, 1
    j    dijkstra_init_loop
    
dijkstra_init_done:
    # dist[start] = 0
    sll  $t4, $s0, 2
    add  $t5, $t2, $t4
    sw   $zero, 0($t5)
    
    li   $s1, 0             # count = 0

dijkstra_main_loop:
    # Enquanto count < num_entities
    bge  $s1, $s2, dijkstra_done
    
    # 2. Encontrar nó u não visitado com menor dist
    li   $s3, -1            # u = -1
    lw   $t6, INFINITY      # min_val = INF
    
    li   $t0, 0             # v = 0
    
find_min_loop:
    bge  $t0, $s2, find_min_done
    
    # check visited[v]
    la   $t3, visited
    add  $t5, $t3, $t0
    lb   $t7, 0($t5)
    bnez $t7, find_min_next # se visitado, pula
    
    # check dist[v] < min_val
    la   $t2, dist
    sll  $t4, $t0, 2
    add  $t5, $t2, $t4
    lw   $t8, 0($t5)
    
    bge  $t8, $t6, find_min_next
    
    # Novo min
    move $t6, $t8           # min_val = dist[v]
    move $s3, $t0           # u = v
    
find_min_next:
    addi $t0, $t0, 1
    j    find_min_loop
    
find_min_done:
    # Se u == -1 ou dist[u] == INF, terminamos (resto é inalcançável)
    li   $t0, -1
    beq  $s3, $t0, dijkstra_done
    lw   $t6, INFINITY
    
    la   $t2, dist
    sll  $t4, $s3, 2
    add  $t5, $t2, $t4
    lw   $t8, 0($t5)        # dist[u]
    beq  $t8, $t6, dijkstra_done
    
    # 3. Marcar u como visitado
    la   $t3, visited
    add  $t5, $t3, $s3
    li   $t9, 1
    sb   $t9, 0($t5)
    
    # 4. Relaxar vizinhos
    # Para cada v de 0 a num_entities
    li   $t0, 0             # v = 0
    
relax_loop:
    bge  $t0, $s2, relax_done
    
    # Verifica se !visited[v]
    la   $t3, visited
    add  $t5, $t3, $t0
    lb   $t7, 0($t5)
    bnez $t7, relax_next
    
    # Verifica aresta adj[u][v]
    # Endereço = base + (u * MAX_ENTITIES + v) * 4
    li   $t9, 50            # MAX_ENTITIES
    mul  $t4, $s3, $t9      # u * 50
    add  $t4, $t4, $t0      # + v
    sll  $t4, $t4, 2        # * 4
    
    la   $t5, adj_matrix
    add  $t5, $t5, $t4
    lw   $t9, 0($t5)        # peso da aresta
    
    beqz $t9, relax_next    # Se peso 0, não tem aresta
    
    # alt = dist[u] + peso
    # dist[u] já está em $t8 (mas cuidado, $t8 foi usado no loop anterior, recarregar)
    la   $t2, dist
    sll  $t4, $s3, 2
    add  $t5, $t2, $t4
    lw   $t8, 0($t5)        # dist[u]
    
    add  $t8, $t8, $t9      # alt
    
    # Se alt < dist[v]
    sll  $t4, $t0, 2
    add  $t5, $t2, $t4      # &dist[v]
    lw   $t7, 0($t5)        # dist[v]
    
    bge  $t8, $t7, relax_next
    
    sw   $t8, 0($t5)        # dist[v] = alt
    
relax_next:
    addi $t0, $t0, 1
    j    relax_loop

relax_done:
    addi $s1, $s1, 1        # count++
    j    dijkstra_main_loop

dijkstra_done:
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    lw   $s3, 16($sp)
    addi $sp, $sp, 20
    jr   $ra

# -----------------------------------------------------------------------------
# Função: str_contains
# Descrição: Verifica se string haystack contém needle (case insensitive)
# Entrada: $a0 = haystack, $a1 = needle
# Retorno: $v0 = 1 se contém, 0 se não
# -----------------------------------------------------------------------------
str_contains:
    move $t0, $a0           # haystack ptr
    move $t1, $a1           # needle ptr
    
    # Se needle vazio, retorna 1? Ou 0? Vamos assumir 0 para segurança
    lb   $t2, 0($t1)
    beqz $t2, str_not_found
    
sc_loop_h:
    lb   $t2, 0($t0)        # char haystack
    beqz $t2, str_not_found # fim haystack
    
    # Tenta match a partir daqui
    move $t3, $t0           # temp haystack
    move $t4, $t1           # temp needle
    
sc_loop_n:
    lb   $t5, 0($t4)        # char needle
    beqz $t5, str_found     # fim needle = match completo!
    
    lb   $t6, 0($t3)        # char haystack temp
    beqz $t6, sc_next_h     # fim haystack temp antes de needle = fail
    
    # Comparação Case Insensitive
    # Converte ambos para lowercase (ou uppercase) apenas para comparação
    
    # Char needle ($t5)
    li   $t9, 65            # 'A'
    blt  $t5, $t9, check_h
    li   $t9, 90            # 'Z'
    bgt  $t5, $t9, check_h
    addi $t5, $t5, 32       # to lower
    
check_h:
    # Char haystack ($t6)
    li   $t9, 65            # 'A'
    blt  $t6, $t9, compare
    li   $t9, 90            # 'Z'
    bgt  $t6, $t9, compare
    addi $t6, $t6, 32       # to lower

compare:
    bne  $t5, $t6, sc_next_h
    
    addi $t3, $t3, 1
    addi $t4, $t4, 1
    j    sc_loop_n
    
sc_next_h:
    addi $t0, $t0, 1
    j    sc_loop_h
    
str_found:
    li   $v0, 1
    jr   $ra
    
str_not_found:
    li   $v0, 0
    jr   $ra

# -----------------------------------------------------------------------------
# Função: remove_newline
# Descrição: Substitui \n e \r por \0
# Entrada: $a0 = string address
# -----------------------------------------------------------------------------
remove_newline:
    move $t0, $a0
rn_loop:
    lb   $t1, 0($t0)
    beqz $t1, rn_done
    
    li   $t2, 10            # \n
    beq  $t1, $t2, rn_replace
    
    li   $t2, 13            # \r
    beq  $t1, $t2, rn_replace
    
    addi $t0, $t0, 1
    j    rn_loop
rn_replace:
    sb   $zero, 0($t0)
rn_done:
    jr   $ra
