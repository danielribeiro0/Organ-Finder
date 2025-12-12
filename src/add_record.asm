# add_record.asm
# Módulo para adicionar novos registros

.data
    prompt_type:    .asciiz "\nDigite o Tipo (C/D): "
    prompt_name:    .asciiz "Digite o Nome: "
    prompt_city:    .asciiz "Digite a Cidade: "
    prompt_org:     .asciiz "Digite os Orgaos (sep por virgula): "
    success_msg:    .asciiz "\nRegistro adicionado e salvo com sucesso!\n"
    msg_err_type:   .asciiz "Erro: Tipo deve ser 'C' ou 'D'. Tente novamente.\n"
    full_msg: .asciiz "Erro: limite maximo de entidades atingido. Nao e possivel adicionar novos registros.\n"

.text
.globl add_new_record

# -----------------------------------------------------------------------------
# Função: add_new_record
# Descrição: Coleta dados do usuário e adiciona nova entidade
# -----------------------------------------------------------------------------
add_new_record:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    # Verifica capacidade (MAX = 50)
    lw   $t0, num_entities
    li   $t1, 50
    bge  $t0, $t1, ar_full
    
    # Calcula índice da nova entidade = num_entities
    move $s0, $t0       # s0 = index
    
    # ---------------------------------------------------------
    # 1. Definir ID
    # ---------------------------------------------------------
    # ID = index
    move $s1, $s0
    
    la   $t2, ent_id
    sll  $t3, $s0, 2
    add  $t2, $t2, $t3
    sw   $s1, 0($t2)
    
    # ---------------------------------------------------------
    # 2. Ler Tipo (Validado)
    # ---------------------------------------------------------
    # Buffer destino
    la   $t2, ent_type
    add  $t2, $t2, $s0      # char array

ar_read_type_loop:
    li   $v0, 4
    la   $a0, prompt_type
    syscall
    
    addi $sp, $sp, -4       # mini buffer
    move $a0, $sp
    li   $a1, 4             # ler até 3 chars
    li   $v0, 8             # read_string
    syscall
    
    lb   $t3, 0($sp)        # pega primeiro char
    addi $sp, $sp, 4        # free mini buffer
    
    # Validação C/D (case insensitive support)
    li   $t4, 67            # 'C'
    beq  $t3, $t4, ar_type_valid
    li   $t4, 99            # 'c'
    beq  $t3, $t4, ar_fix_c
    
    li   $t4, 68            # 'D'
    beq  $t3, $t4, ar_type_valid
    li   $t4, 100           # 'd'
    beq  $t3, $t4, ar_fix_d
    
    # Se chegou aqui, inválido
    li   $v0, 4
    la   $a0, msg_err_type
    syscall
    j    ar_read_type_loop

ar_fix_c:
    li   $t3, 67            # Force upper 'C'
    j    ar_type_valid

ar_fix_d:
    li   $t3, 68            # Force upper 'D'
    j    ar_type_valid
    
ar_type_valid:
    sb   $t3, 0($t2)        # salva em ent_type
    
    # Consumir restante de linha se necessário?
    # Se user digitou apenas C\n, o \n foi lido?
    # read_string lê \n se couber. se leu C\n, ok.
    
    # ---------------------------------------------------------
    # 3. Ler Nome
    # ---------------------------------------------------------
    li   $v0, 4
    la   $a0, prompt_name
    syscall
    
    la   $t2, ent_name
    sll  $t3, $s0, 6        # 64 bytes
    add  $a0, $t2, $t3
    li   $a1, 63            # max 63
    li   $v0, 8
    syscall
    
    # Remover \n do final se existir
    move $a1, $a0
    jal  chomp
    
    # ---------------------------------------------------------
    # 4. Ler Cidade
    # ---------------------------------------------------------
    li   $v0, 4
    la   $a0, prompt_city
    syscall
    
    la   $t2, ent_city
    sll  $t3, $s0, 6
    add  $a0, $t2, $t3
    li   $a1, 63
    li   $v0, 8
    syscall
    
    move $a1, $a0
    jal  chomp

    # ---------------------------------------------------------
    # 5. Ler Orgaos
    # ---------------------------------------------------------
    li   $v0, 4
    la   $a0, prompt_org
    syscall
    
    la   $t2, ent_organs
    sll  $t3, $s0, 7        # 128 bytes
    add  $a0, $t2, $t3
    li   $a1, 127
    li   $v0, 8
    syscall
    
    move $a1, $a0
    jal  chomp

    # ---------------------------------------------------------
    # Atualizar Contador e Salvar
    # ---------------------------------------------------------
    addi $t0, $s0, 1
    sw   $t0, num_entities
    
    jal  save_data
    
    li   $v0, 4
    la   $a0, success_msg
    syscall
    
    j    ar_done

ar_full:
    li   $v0, 4
    la   $a0, full_msg
    syscall

ar_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# -----------------------------------------------------------------------------
# Helper: chomp
# Remove \n do final da string
# Input: $a1 = address string
# -----------------------------------------------------------------------------
chomp:
    move $t0, $a1
ch_loop:
    lb   $t1, 0($t0)
    beqz $t1, ch_end
    li   $t2, 10        # \n
    beq  $t1, $t2, ch_replace
    addi $t0, $t0, 1
    j    ch_loop
ch_replace:
    sb   $zero, 0($t0)
ch_end:
    jr   $ra
