# readfile.asm
# Módulo para leitura e parsing do arquivo de dados de entrada

.data
    filename:       .asciiz "dados.txt"
    error_msg:      .asciiz "Erro ao abrir arquivo!\n"
    
    # Buffers globais para dados parseados
    .globl num_entities
    num_entities:   .word 0
    
    .globl ent_id
    ent_id:         .space 200      # 50 entidades * 4 bytes
    
    .globl ent_type
    ent_type:       .space 50       # 50 entidades * 1 byte
    
    .globl ent_name
    ent_name:       .space 3200     # 50 entidades * 64 bytes
    
    .globl ent_city
    ent_city:       .space 3200     # 50 entidades * 64 bytes
    
    .globl ent_organs
    ent_organs:     .space 6400     # 50 entidades * 128 bytes
    
    .globl num_edges
    num_edges:      .word 0
    
    .globl edge_u
    edge_u:         .space 200      # 50 arestas * 4 bytes
    
    .globl edge_v
    edge_v:         .space 200      # 50 arestas * 4 bytes
    
    .globl edge_w
    edge_w:         .space 200      # 50 arestas * 4 bytes
    
    # Buffer de arquivo
    buffer:         .space 8192     # Buffer de 8KB
    
.text
.globl readfile

# -----------------------------------------------------------------------------
# Procedimento: readfile
# Descrição: Lê 'dados.txt' e popula arrays globais
# -----------------------------------------------------------------------------
readfile:
    addi $sp, $sp, -16
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)

    # Abrir arquivo
    li   $v0, 13            # abrir arquivo
    la   $a0, filename
    li   $a1, 0             # flag de leitura
    li   $a2, 0
    syscall
    move $s0, $v0           # salva descritor de arquivo
    
    bltz $s0, file_error

    # Ler arquivo
    li   $v0, 14            # ler arquivo
    move $a0, $s0
    la   $a1, buffer
    li   $a2, 8192
    syscall
    move $s1, $v0           # bytes lidos
    
    # Fechar arquivo
    li   $v0, 16            # fechar arquivo
    move $a0, $s0
    syscall
    
    # Inicializa ponteiro do buffer
    la   $s2, buffer        # $s2 é nossa posição atual no buffer

    # ---------------------------------------------------------
    # Parse Número de Entidades
    # ---------------------------------------------------------
    li   $a1, 10            # delimitador: nova linha
    jal  parse_int
    sw   $v0, num_entities
    
    # ---------------------------------------------------------
    # Loop de Parse de Entidades
    # ---------------------------------------------------------
    lw   $t0, num_entities
    li   $t1, 0             # i = 0
    
parse_ent_loop:
    beq  $t1, $t0, parse_edges_start
    
    # 1. ID (int) ;
    li   $a1, 59            # delimitador: ';'
    jal  parse_int
    
    # Armazena ID
    la   $t2, ent_id
    sll  $t3, $t1, 2        # i * 4
    add  $t2, $t2, $t3
    sw   $v0, 0($t2)
    
    # 2. Tipo (char/string) ;
    # Vamos ler como string mas é apenas 1 char geralmente
    la   $t2, ent_type
    add  $t2, $t2, $t1      # i * 1 (array de bytes)
    move $a0, $t2           # dest
    li   $a1, 59            # delimitador: ';'
    li   $a2, 1             # max len: 1
    jal  parse_string
    
    # 3. Nome (string) ;
    la   $t2, ent_name
    sll  $t3, $t1, 6        # i * 64
    add  $t2, $t2, $t3
    move $a0, $t2           # dest
    li   $a1, 59            # delimitador: ';'
    li   $a2, 63            # max len: 63 (+1 null)
    jal  parse_string
    
    # 4. Cidade (string) ;
    la   $t2, ent_city
    sll  $t3, $t1, 6        # i * 64
    add  $t2, $t2, $t3
    move $a0, $t2           # dest
    li   $a1, 59            # delimitador: ';'
    li   $a2, 63            # max len: 63 (+1 null)
    jal  parse_string
    
    # 5. Órgãos (string) \n
    la   $t2, ent_organs
    sll  $t3, $t1, 7        # i * 128
    add  $t2, $t2, $t3
    move $a0, $t2           # dest
    li   $a1, 10            # delimitador: nova linha
    li   $a2, 127           # max len: 127 (+1 null)
    jal  parse_string
    
    addi $t1, $t1, 1
    j    parse_ent_loop

    # ---------------------------------------------------------
    # Parse Número de Arestas
    # ---------------------------------------------------------
parse_edges_start:
    li   $a1, 10            # delimitador: nova linha
    jal  parse_int
    sw   $v0, num_edges
    
    # ---------------------------------------------------------
    # Loop de Parse de Arestas
    # ---------------------------------------------------------
    lw   $t0, num_edges
    li   $t1, 0             # i = 0
    
parse_edge_loop:
    beq  $t1, $t0, read_done
    
    # 1. U (int) ,
    li   $a1, 44            # delimitador: ','
    jal  parse_int
    
    la   $t2, edge_u
    sll  $t3, $t1, 2
    add  $t2, $t2, $t3
    sw   $v0, 0($t2)
    
    # 2. V (int) ,
    li   $a1, 44            # delimitador: ','
    jal  parse_int
    
    la   $t2, edge_v
    sll  $t3, $t1, 2
    add  $t2, $t2, $t3
    sw   $v0, 0($t2)
    
    # 3. W (int) \n
    li   $a1, 10            # delimitador: nova linha
    jal  parse_int
    
    la   $t2, edge_w
    sll  $t3, $t1, 2
    add  $t2, $t2, $t3
    sw   $v0, 0($t2)
    
    addi $t1, $t1, 1
    j    parse_edge_loop

read_done:
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

file_error:
    li   $v0, 4
    la   $a0, error_msg
    syscall
    j    read_done

# -----------------------------------------------------------------------------
# Auxiliar: parse_int
# Entradas: $s2 (ptr buffer), $a1 (char delimitador)
# Saídas: $v0 (inteiro), atualiza $s2
# -----------------------------------------------------------------------------
parse_int:
    li   $v0, 0             # resultado
    li   $t8, 0             # char
    
pi_loop:
    lb   $t8, 0($s2)        # carrega char
    addi $s2, $s2, 1        # avança ptr
    
    # Verifica delimitador
    beq  $t8, $a1, pi_done
    
    # Verifica CR (13) - ignora
    li   $t9, 13
    beq  $t8, $t9, pi_loop
    
    # Verifica null - fim
    beqz $t8, pi_done
    
    # Converte dígito
    sub  $t8, $t8, 48       # '0' é 48
    mul  $v0, $v0, 10
    add  $v0, $v0, $t8
    
    j    pi_loop
    
pi_done:
    jr   $ra

# -----------------------------------------------------------------------------
# Auxiliar: parse_string
# Entradas: $s2 (ptr buffer), $a0 (ptr dest), $a1 (char delimitador), $a2 (max len)
# Saídas: atualiza $s2, escreve em $a0
# -----------------------------------------------------------------------------
parse_string:
    move $t6, $a0           # ptr dest
    li   $t7, 0             # contador de chars escritos

ps_loop:
    lb   $t8, 0($s2)        # carrega char
    addi $s2, $s2, 1        # avança ptr buffer
    
    # Verifica delimitador
    beq  $t8, $a1, ps_done
    
    # Verifica CR (13) - ignora
    li   $t9, 13
    beq  $t8, $t9, ps_loop
    
    # Verifica null
    beqz $t8, ps_done
    
    # Verifica limite de buffer
    bge  $t7, $a2, ps_skip_store # Se atingiu limite, não salva, mas continua consumindo até delimitador
    
    # Armazena char
    sb   $t8, 0($t6)
    addi $t6, $t6, 1
    addi $t7, $t7, 1
    
    j    ps_loop

ps_skip_store:
    # Opcional: loop apenas para consumir até o delimitador se estourou o buffer
    j    ps_loop
    
ps_done:
    sb   $zero, 0($t6)      # termina string com null
    jr   $ra
