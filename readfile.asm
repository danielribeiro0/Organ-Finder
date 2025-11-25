# Módulo do código de entrada e saída de arquivos
# Leitura e escrita de arquivos para o sistema de órgãos

#-----------------------------------------------------------------------------

# Formato do arquivo de leitura:

# NUMERO DE CIDADES
# CIDADE 1 (ID, NOME, ORGÂOS DISPONIVEIS)
# CIDADE 2 (ID, NOME, ORGÂOS DISPONIVEIS)
# ...
# CIDADE N (ID, NOME, ORGÂOS DISPONIVEIS)
# CONEXÕES (CIDADE ORIGEM, CIDADE DESTINO, DISTANCIA EM KM)

#-------------------------------------------------------------------------------

#Formato do arquivo de saída:

#=== RESULTADO DA BUSCA ===
# ORIGEM: (CIDADE ORIGEM)
# DESTINO: (CIDADE DESTINO)
# ORGAO SOLICITADO (ORGAO SOLICITADO)

#CAMINHO ENCONTRADO:
#(CIDADE ORIGEM) -> (CIDADE 1) -> (CIDADE 2) -> (CIDADE N) -> (CIDADE DESTINO)

# DISTANCIA TOTAL: (SOMA DAS DISTANCIAS ENTRE AS CIDADES NO CAMINHO MINIMO ENCONTRADO EM KM)

# ORGAO ENCONTRADO: (BOOLEANO, SIM OU NÂO)

#----------------------------------------------------------------------------------
#Fazer parsing do arquivo de texto de entrada e preencher vetores globais

.data
.globl num_entities
num_entities: .word 0

.globl ent_id
ent_id: .space 100*4 #até 100 entidades, 4 bytes cada

.globl ent_name
ent_name: .space 100*64 #cada nome até 64 bytes

.globl ent_city
ent_ciy: .space 100*64

.globl ent_organs
ent_organs: .space 100*128

.globl num_edges
num_edges: .word 0

.globl edge_u
edge_u: .space 400

.globl edge_v
edge_v: .space 400

.globl edge_wheight
edge_w: .space 400

buffer: .space 4098
filename: .asciiz "dados.txt"

newline: .byte 10,0
semicolon: .byte ";",0
comma: .byte ",",0

.text
.globl read_file
readfile:
	#abrir arquivo dados.txt
	li $v0, 13
	la $a0, filename
	li $a1, 0
	li $a2, 0
	syscall
	move $s0, $v0
	
	bltz $s0, error #caso de erro ao abrir
	
	#ler arquivo com buffer
	li $v0, 14
	move $a0, $s0
	la $a1, buffer
	li $a2, 4096
	syscall
	move $s1, $v0	#numero de bytes lidos
	
	#fechar arquivo
	li $v0, 16
	la $a0, $s0
	syscall
	
	#inicializar ponteiro
	la $s2, buffer #s2 -> inicio do texto
	
#-----------------------------------
	
		


