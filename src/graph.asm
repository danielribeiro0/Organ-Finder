.include "readfile.asm"

.eqv MAX_ENTITIES 50
.eqv MAX_EDGES_PER_NODE 50

.data

.globl adj_matrix
adj_matrix: .space 10000    # 50 * 50 * 4 (MAX_ENTITIES * MAX_ENTITIES * 4 BYTES)

.text
.globl add_edge
.globl init_graph

add_edge:
    ############ Cálculo do endereço [u][v] ############
    mul  $t0, $a0, MAX_ENTITIES     # t0 = u * MAX
    add  $t0, $t0, $a1              # t0 = u*MAX + v
    sll  $t0, $t0, 2                # t0 *= 4 (word size)

    la   $t1, adj_matrix            # base da matriz
    add  $t1, $t1, $t0              # t1 = &adj[u][v]
    sw   $a2, 0($t1)                # salva peso

    ###### Cálculo do endereço [v][u] (simétrico) ######
    mul  $t0, $a1, MAX_ENTITIES     # v*MAX
    add  $t0, $t0, $a0              # v*MAX + u
    sll  $t0, $t0, 2

.include "readfile.asm"

.eqv MAX_ENTITIES 50
.eqv MAX_EDGES_PER_NODE 50

.data

.globl adj_matrix
adj_matrix: .space 10000    # 50 * 50 * 4 (MAX_ENTITIES * MAX_ENTITIES * 4 BYTES)

.text
.globl add_edge
.globl init_graph

add_edge:
    ############ Cálculo do endereço [u][v] ############
    mul  $t0, $a0, MAX_ENTITIES     # t0 = u * MAX
    add  $t0, $t0, $a1              # t0 = u*MAX + v
    sll  $t0, $t0, 2                # t0 *= 4 (word size)

    la   $t1, adj_matrix            # base da matriz
    add  $t1, $t1, $t0              # t1 = &adj[u][v]
    sw   $a2, 0($t1)                # salva peso

    ###### Cálculo do endereço [v][u] (simétrico) ######
    mul  $t0, $a1, MAX_ENTITIES     # v*MAX
    add  $t0, $t0, $a0              # v*MAX + u
    sll  $t0, $t0, 2

    la   $t1, adj_matrix
    add  $t1, $t1, $t0              # &adj[v][u]
    sw   $a2, 0($t1)                # salva peso

    jr   $ra

init_graph:
    addi $sp, $sp, -12
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)        # Para guardar num_edges
    sw   $s1, 8($sp)        # Para guardar i

    ########################################
    # 1. ZERA MATRIZ DE ADJACÊNCIA
    ########################################

    la   $t0, adj_matrix    # ponteiro base
    li   $t1, 2500          # total = 50*50 = 2500 words
    li   $t2, 0             # valor a gravar

clear_loop:
    beq  $t1, $zero, clear_done
    sw   $t2, 0($t0)         # adj[u][v] = 0
    addi $t0, $t0, 4         # próximo word
    addi $t1, $t1, -1
    j clear_loop

clear_done:

    ########################################
    # 2. CARREGAR arestas e inserir no grafo
    ########################################

    lw   $s0, num_edges      # s0 = número total de arestas
    li   $s1, 0              # s1 = i = 0

build_loop:

    beq  $s1, $s0, init_end  # se i == num_edges → terminou

    ####### U #######
    la   $t2, edge_u
    sll  $t3, $s1, 2         # offset = i * 4
    add  $t2, $t2, $t3
    lw   $a0, 0($t2)         # a0 = U

    ####### V #######
    la   $t4, edge_v
    add  $t4, $t4, $t3
    lw   $a1, 0($t4)         # a1 = V

    ####### PESO (W) #######
    la   $t5, edge_w
    add  $t5, $t5, $t3
    lw   $a2, 0($t5)         # a2 = W

    jal add_edge             # add_edge(U, V, W)

    addi $s1, $s1, 1         # i++
    j build_loop

init_end:
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra