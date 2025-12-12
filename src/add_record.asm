# add_record.asm
# Módulo para adicionar novos registros

.data
    prompt_type:    .asciiz "\nDigite o Tipo (C/D): "
    prompt_name:    .asciiz "Digite o Nome: "
    prompt_city:    .asciiz "Digite a Cidade: "
    prompt_org:     .asciiz "Digite os Orgaos (sep por virgula): "
    success_msg:    .asciiz "\nRegistro adicionado e salvo com sucesso!\n"
    merge_msg:      .asciiz "\nRegistro existente encontrado! Orgaos adicionados ao registro existente.\n"
    msg_err_type:   .asciiz "Erro: Tipo deve ser 'C' ou 'D'. Tente novamente.\n"
    full_msg:       .asciiz "Erro: limite maximo de entidades atingido. Nao e possivel adicionar novos registros.\n"
    comma_sep:      .asciiz ","

.text
.globl add_new_record

# -----------------------------------------------------------------------------
# Função: add_new_record
# Descrição: Coleta dados do usuário e adiciona nova entidade
#            Se o nome ja existir, faz MERGE (concatena orgaos).
# -----------------------------------------------------------------------------
add_new_record:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    # Verifica capacidade (MAX = 50)
    lw   $t0, num_entities
    li   $t1, 50
    bge  $t0, $t1, ar_full
    
    # Calcula índice da nova entidade = num_entities (Candidato)
    move $s0, $t0       # s0 = index (candidate slot)
    
    # ---------------------------------------------------------
    # 1. Definir ID Temporário
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
    beq  $t3, $t4, ar_type_valid_upper
    li   $t4, 99            # 'c'
    beq  $t3, $t4, ar_fix_c
    
    li   $t4, 68            # 'D'
    beq  $t3, $t4, ar_type_valid_upper
    li   $t4, 100           # 'd'
    beq  $t3, $t4, ar_fix_d
    
    # Se chegou aqui, inválido
    li   $v0, 4
    la   $a0, msg_err_type
    syscall
    j    ar_read_type_loop

ar_fix_c:
    li   $t3, 67            # Force upper 'C'
    j    ar_type_valid_upper

ar_fix_d:
    li   $t3, 68            # Force upper 'D'
    j    ar_type_valid_upper
    
ar_type_valid_upper:
    sb   $t3, 0($t2)        # salva em ent_type
    
    # ---------------------------------------------------------
    # 3. Ler Nome e Converter para UPPERCASE
    # ---------------------------------------------------------
    li   $v0, 4
    la   $a0, prompt_name
    syscall
    
    la   $t2, ent_name
    sll  $t3, $s0, 6        # 64 bytes
    add  $a0, $t2, $t3
    move $s2, $a0           # s2 = endereço do NOME atual
    li   $a1, 63            # max 63
    li   $v0, 8
    syscall
    
    # Remover \n
    move $a1, $s2
    jal  chomp
    
    # To Upper
    move $a0, $s2
    jal  str_to_upper       # Converte nome para maiúsculas
    
    # ---------------------------------------------------------
    # 3.1 CHECK FOR DUPLICATES (MERGE LOGIC)
    # ---------------------------------------------------------
    # Iterar de 0 até num_entities - 1
    # Comparar ent_name[i] com s2 (ent_name[candidate])
    
    lw   $t5, num_entities  # t5 limit
    li   $t6, 0             # t6 counters (i)
    
check_dup_loop:
    beq  $t6, $t5, no_duplicate_found
    
    # Get address of ent_name[i]
    la   $t7, ent_name
    sll  $t8, $t6, 6        # i * 64
    add  $t7, $t7, $t8      # t7 = &ent_name[i]
    
    # Compare strings (t7 vs s2)
    move $a0, $t7
    move $a1, $s2
    
    # Save regs before call (just in case, though str_cmp handles it)
    # We need t6, t5, s0, etc.
    addi $sp, $sp, -12
    sw   $t6, 0($sp)
    sw   $t5, 4($sp)
    sw   $ra, 8($sp)
    
    jal  str_cmp
    
    lw   $ra, 8($sp)
    lw   $t5, 4($sp)
    lw   $t6, 0($sp)
    addi $sp, $sp, 12
    
    # if v0 == 0, match found!
    beqz $v0, duplicate_found_at_index
    
    addi $t6, $t6, 1
    j    check_dup_loop

duplicate_found_at_index:
    # $t6 possui o índice da entidade existente
    move $s3, $t6           # s3 = indice existente onde faremos o merge
    j    continue_input_merge

no_duplicate_found:
    li   $s3, -1            # s3 = -1 significa NOVA entidade
    
continue_input_merge:

    # ---------------------------------------------------------
    # 4. Ler Cidade (Mesmo se for merge, vamos ler para nao quebrar UX
    #    mas se for merge, ignoraremos ou substituiremos?? 
    #    Vamos substituir para atualizar dados caso usuario queira corrigir)
    # ---------------------------------------------------------
    li   $v0, 4
    la   $a0, prompt_city
    syscall
    
    la   $t2, ent_city
    sll  $t3, $s0, 6        # Usa slot do candidato
    add  $a0, $t2, $t3
    move $s4, $a0           # s4 = end cidade candidato
    li   $a1, 63
    li   $v0, 8
    syscall
    
    move $a1, $s4
    jal  chomp
    
    move $a0, $s4
    jal  str_to_upper       # Cidade UPPERCASE

    # ---------------------------------------------------------
    # 5. Ler Orgaos
    # ---------------------------------------------------------
    li   $v0, 4
    la   $a0, prompt_org
    syscall
    
    la   $t2, ent_organs
    sll  $t3, $s0, 7        # 128 bytes - slot candidato
    add  $a0, $t2, $t3
    move $s5, $a0           # s5 = end orgaos candidato
    li   $a1, 127
    li   $v0, 8
    syscall
    
    move $a1, $s5
    jal  chomp
    
    move $a0, $s5
    jal  str_to_upper       # Orgaos UPPERCASE

    # ---------------------------------------------------------
    # FINALIZAR: MERGE OU NOVO?
    # ---------------------------------------------------------
    li   $t9, -1
    beq  $s3, $t9, finalize_new_record
    
    # === MERGE PATH ===
    # s3 = indice da entidade original
    # s5 = orgaos novos (no slot candidato)
    
    # 1. Obter endereço de orgaos destino (ent_organs[s3])
    la   $t2, ent_organs
    sll  $t8, $s3, 7        # s3 * 128
    add  $t2, $t2, $t8      # t2 = dest
    
    # 2. Verificar se dest já tem orgaos (len > 0)
    move $a0, $t2
    addi $sp, $sp, -8
    sw   $t2, 0($sp)
    sw   $ra, 4($sp)
    jal  str_len
    lw   $ra, 4($sp)
    lw   $t2, 0($sp)
    addi $sp, $sp, 8
    
    # Se len > 0, adicionar virgula antes
    beqz $v0, do_cat_only
    
    # Adicionar virgula
    move $a0, $t2
    la   $a1, comma_sep
    addi $sp, $sp, -8
    sw   $t2, 0($sp)
    sw   $ra, 4($sp)
    jal  str_cat
    lw   $ra, 4($sp)
    lw   $t2, 0($sp)
    addi $sp, $sp, 8
    
do_cat_only:
    # Concatenar novos orgaos
    move $a0, $t2           # dest (original)
    move $a1, $s5           # src (candidato)
    jal  str_cat
    
    # Salvar arquivo (NÃO incrementa num_entities)
    jal  save_data
    
    li   $v0, 4
    la   $a0, merge_msg
    syscall
    
    j    ar_done

finalize_new_record:
    # ---------------------------------------------------------
    # Atualizar Contador e Salvar (NOVO)
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

# -----------------------------------------------------------------------------
# Helper: str_to_upper
# Converte string em $a0 para UPPERCASE (in-place)
# -----------------------------------------------------------------------------
str_to_upper:
    move $t0, $a0
stu_loop:
    lb   $t1, 0($t0)
    beqz $t1, stu_end
    
    # Check 'a' <= char <= 'z'
    li   $t2, 97    # 'a'
    blt  $t1, $t2, stu_next
    li   $t2, 122   # 'z'
    bgt  $t1, $t2, stu_next
    
    # Convert: char = char - 32
    addi $t1, $t1, -32
    sb   $t1, 0($t0)
    
stu_next:
    addi $t0, $t0, 1
    j    stu_loop
stu_end:
    jr   $ra

# -----------------------------------------------------------------------------
# Helper: str_cmp
# Compara $a0 e $a1. Return $v0 = 0 se igual, != 0 se diferente
# -----------------------------------------------------------------------------
str_cmp:
    move $t0, $a0
    move $t1, $a1
sc_loop:
    lb   $t2, 0($t0)
    lb   $t3, 0($t1)
    
    bne  $t2, $t3, sc_diff
    beqz $t2, sc_equal
    
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j    sc_loop

sc_diff:
    li   $v0, 1     # Diff
    jr   $ra
sc_equal:
    li   $v0, 0     # Equal
    jr   $ra

# -----------------------------------------------------------------------------
# Helper: str_len
# Retorna length de $a0 em $v0
# -----------------------------------------------------------------------------
str_len:
    move $t0, $a0
    li   $v0, 0
sl_loop:
    lb   $t1, 0($t0)
    beqz $t1, sl_end
    addi $v0, $v0, 1
    addi $t0, $t0, 1
    j    sl_loop
sl_end:
    jr   $ra

# -----------------------------------------------------------------------------
# Helper: str_cat
# Concatena string $a1 no final de $a0.
# $a0 deve ter espaço suficiente.
# -----------------------------------------------------------------------------
str_cat:
    move $t0, $a0
    move $t1, $a1
    
    # Find end of t0
cat_find_end:
    lb   $t2, 0($t0)
    beqz $t2, cat_copy
    addi $t0, $t0, 1
    j    cat_find_end
    
cat_copy:
    lb   $t3, 0($t1)
    sb   $t3, 0($t0)
    beqz $t3, cat_done  # Copied null terminator
    
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j    cat_copy

cat_done:
    jr   $ra
