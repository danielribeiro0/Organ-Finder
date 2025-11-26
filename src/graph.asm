.eqv MAX_ENTITIES 50
.eqv MAX_EDGES_PER_NODE 50

.data

adj_list: .space 10000      # MAX_ENTITIES * MAX_EDGES_PER_NODE * 4	(50 * 50 * 4)
adj_weight: .space 10000    # MAX_ENTITIES * MAX_EDGES_PER_NODE * 4	(50 * 50 * 4)
adj_count: .space 200       # MAX_ENTITIES * 4                      (50 * 4)

.text

li $v0 10
syscall