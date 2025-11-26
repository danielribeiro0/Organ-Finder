# Input File
## Constants
```txt
max_entities = 50
max_edges_per_entity = 50
```

## Scheme
```txt
number_of_entities
id;type;name;city;list_of_organs
number_of_edges
id,id,distance
```

## Input Example
```txt
3
1;C;santa casa;pindamonhangaba;rim,coracao
2;C;hospital da vida;sao jose dos campos;
3;D;jose;taubate;figado
3
1,2,60
1,3,15
2,3,45
```