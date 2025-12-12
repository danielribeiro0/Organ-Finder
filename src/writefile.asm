# writefile.asm
# Módulo para escrever os dados de volta no arquivo

.data
    outfile:        .asciiz "../data/dados.txt"
    newline:        .asciiz "\n"
    semicolon:      .asciiz ";"
    comma:          .asciiz ","
    write_err:      .asciiz "Erro ao escrever no arquivo!\n"
    
    # Buffer local para conversão itoa
    itoa_buf:       .space 16

.text
.globl save_data

# -----------------------------------------------------------------------------
# Função: save_data
# Descrição: Salva todos os dados da memória de volta para dados.txt
# -----------------------------------------------------------------------------
save_data:
    addi $sp, $sp, -20
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)        # file descriptor
    sw   $s1, 8($sp)        # iterador
    sw   $s2, 12($sp)       # limit
    sw   $s3, 16($sp)       # temp

    # Abrir arquivo para escrita (truncar)
    li   $v0, 13            # open
    la   $a0, outfile
    li   $a1, 1             # O_WRONLY | O_CREAT | O_TRUNC (val 1 in MARS)
    li   $a2, 0
    syscall
    move $s0, $v0
    
    bltz $s0, write_error

    # ---------------------------------------------------------
    # Escrever Número de Entidades
    # ---------------------------------------------------------
    lw   $a0, num_entities
    jal  write_int_line

    # ---------------------------------------------------------
    # Loop Entidades
    # ---------------------------------------------------------
    lw   $s2, num_entities
    li   $s1, 0             # i = 0

wd_ent_loop:
    beq  $s1, $s2, wd_edges_start

    # ID
    la   $t1, ent_id
    sll  $t2, $s1, 2
    add  $t1, $t1, $t2
    lw   $a0, 0($t1)
    jal  write_int

    # ;
    la   $a0, semicolon
    jal  write_str

    # Type
    # ent_type é byte array
    la   $t1, ent_type
    add  $t1, $t1, $s1
    lb   $a0, 0($t1)
    jal  write_char

    # ;
    la   $a0, semicolon
    jal  write_str

    # Name
    la   $t1, ent_name
    sll  $t2, $s1, 6
    add  $a0, $t1, $t2
    jal  write_str
    
    # ;
    la   $a0, semicolon
    jal  write_str

    # City
    la   $t1, ent_city
    sll  $t2, $s1, 6
    add  $a0, $t1, $t2
    jal  write_str
    
    # ;
    la   $a0, semicolon
    jal  write_str

    # Organs
    la   $t1, ent_organs
    sll  $t2, $s1, 7
    add  $a0, $t1, $t2
    jal  write_str
    
    # \n
    la   $a0, newline
    jal  write_str

    addi $s1, $s1, 1
    j    wd_ent_loop

    # ---------------------------------------------------------
    # Escrever Número de Arestas
    # ---------------------------------------------------------
wd_edges_start:
    lw   $a0, num_edges
    jal  write_int_line

    # ---------------------------------------------------------
    # Loop Arestas
    # ---------------------------------------------------------
    lw   $s2, num_edges
    li   $s1, 0             # i = 0

wd_edge_loop:
    beq  $s1, $s2, wd_done

    # U
    la   $t1, edge_u
    sll  $t2, $s1, 2
    add  $t1, $t1, $t2
    lw   $a0, 0($t1)
    jal  write_int

    # ,
    la   $a0, comma
    jal  write_str

    # V
    la   $t1, edge_v
    sll  $t2, $s1, 2
    add  $t1, $t1, $t2
    lw   $a0, 0($t1)
    jal  write_int

    # ,
    la   $a0, comma
    jal  write_str

    # W
    la   $t1, edge_w
    sll  $t2, $s1, 2
    add  $t1, $t1, $t2
    lw   $a0, 0($t1)
    jal  write_int

    # \n
    la   $a0, newline
    jal  write_str

    addi $s1, $s1, 1
    j    wd_edge_loop

wd_done:
    # Fechar arquivo
    li   $v0, 16
    move $a0, $s0
    syscall

    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    lw   $s3, 16($sp)
    addi $sp, $sp, 20
    jr   $ra

write_error:
    li   $v0, 4
    la   $a0, write_err
    syscall
    
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    lw   $s3, 16($sp)
    addi $sp, $sp, 20
    jr   $ra

# -----------------------------------------------------------------------------
# Helper: write_str
# input: $a0 = address of string
# -----------------------------------------------------------------------------
write_str:
    addi $sp, $sp, -4
    sw   $a0, 0($sp)    # Save buffer address
    
    move $t0, $a0
    li   $t1, 0         # Length counter

ws_calc_len:
    lb   $t2, 0($t0)
    beqz $t2, ws_perform_write
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j    ws_calc_len

ws_perform_write:
    move $a2, $t1       # Length
    lw   $a1, 0($sp)    # Buffer address
    move $a0, $s0       # File descriptor (from global s0)
    li   $v0, 15        # Write syscall
    syscall
    
    addi $sp, $sp, 4    # Restore stack
    jr   $ra

# -----------------------------------------------------------------------------
# Helper: write_int
# input: $a0 = integer
# -----------------------------------------------------------------------------
write_int:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    la   $a1, itoa_buf
    jal  itoa           # stores string in itoa_buf
    
    la   $a0, itoa_buf
    jal  write_str
    
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# -----------------------------------------------------------------------------
# Helper: write_int_line
# Write int + newline
# -----------------------------------------------------------------------------
write_int_line:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    jal  write_int
    la   $a0, newline
    jal  write_str
    
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# -----------------------------------------------------------------------------
# Helper: itoa
# input: $a0 = int, $a1 = buffer addr
# output: buffer filled with null terminated string
# -----------------------------------------------------------------------------
itoa:
    move $t0, $a0
    move $t1, $a1       # start
    
    # Caso 0
    bnez $t0, itoa_start
    li   $t2, 48        # char '0'
    sb   $t2, 0($t1)
    sb   $zero, 1($t1)
    jr   $ra

itoa_start:
    # Se negativo não suportado/não esperado, assumimos positivo (IDs, counts)
    
    # Aponta para string reversa temporária ou empilha
    # Vamos usar pilha
    addi $sp, $sp, -16  # max digits
    move $t2, $sp
    
itoa_loop:
    beqz $t0, itoa_copy
    li   $t3, 10
    div  $t0, $t3
    mfhi $t4            # remainder
    mflo $t0            # quotient
    
    add  $t4, $t4, 48   # to char
    sb   $t4, 0($t2)
    addi $t2, $t2, 1
    j    itoa_loop
    
itoa_copy:
    # t2 points one past last digit (which is most significant)
    # sp points to first digit (least significant)
    # We need to reverse into $a1
    addi $t2, $t2, -1
    
itoa_rev:
    blt  $t2, $sp, itoa_end
    lb   $t3, 0($t2)
    sb   $t3, 0($t1)
    addi $t1, $t1, 1
    addi $t2, $t2, -1
    j    itoa_rev
    
itoa_end:
    sb   $zero, 0($t1)
    addi $sp, $sp, 16
    jr   $ra

# -----------------------------------------------------------------------------
# Helper: write_char
# input: $a0 = char byte
# -----------------------------------------------------------------------------
write_char:
    addi $sp, $sp, -4
    sw   $a0, 0($sp)    # Push char to stack (as 4 bytes, but we use address)
                        # Syscall uses address, so we need it in memory
    
    move $a1, $sp       # Buffer addr = stack pointer
    li   $a2, 1         # Length = 1
    move $a0, $s0       # File descriptor
    li   $v0, 15
    syscall
    
    addi $sp, $sp, 4
    jr   $ra
