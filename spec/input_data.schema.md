# Input File
## Constants
```txt
max_entities = 50
max_edges = 1225
```

## Scheme
```txt
number_of_entities
id;name;city;list_of_organs
number_of_edges
id,id,distance
```

## Input Example
```txt
3
1;C1;santa casa;pindamonhangaba;rim,coracao
2;C2;hospital da vida;sao jose dos campos;
3;D1;jose;taubate;figado
3
1,2,60
1,3,15
2,3,45
```