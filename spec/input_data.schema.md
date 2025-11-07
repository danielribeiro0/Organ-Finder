# Input File
## Constants
>max_entities = 50
>max_edges = 1250

## Scheme
>number_of_entities\
>id;name;city;list_of_organs\
>number_of_edges\
>id,id,distance

## Input Example
>3\
>C1;santa casa;pindamonhangaba;rim,coracao;\
>C2;hospital da vida;sao jose dos campos;;\
>D1;jose;taubate;figado;\
>3\
>C1,C2,60;\
>C1,D1,15;\
>C2,D1,45;