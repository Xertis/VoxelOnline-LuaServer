### В процессе создания ядра были перезаписаны некоторые методы из стандартной библиотеки движка, вот их список:

```lua
player.get_dir(pid: number) -> {x, y, z}
```
Позволяет получить вектор направления камеры по pid

(В отличии от оригинального метода, вычисляет вектор не через направление камеры игрока, а через его поворот)
