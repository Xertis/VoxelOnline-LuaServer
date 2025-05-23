Для работы с базами данных предоставляется библиотека **db**.
## Создание бд:

Для создания базы данных используйте:
```python
api.db.db.register() -> nil / number
```
- Если база данных уже существует, он вернёт код **DatabaseExists**

Для того, чтобы узнать, существует ли база данных, используйте:
```python
api.db.db.exists(pack: String) -> Boolean
```
- Принимает айди контент-пака и проверяет существование у пака базы данных

Для того, чтобы авторизоваться, используйте:
```python
api.db.db.login() -> Session / number
```
- Возвращает сессию, для управления базой данных, если база данных не существует, возвращает код **DatabaseNotExists**

Вспомогательная функция, использующаяся при инициализации таблицы:
```python
api.db.items.Column(column_type: String, [необязательный] config: Table) -> Column
```
- Возвращает объект **Column:**  *{column_type, config}*
- **config** на данный момент может иметь всего одно значение `{primary_key=true}` который отвечает за то, является ли эта колонка индексом для всех элементов в ней
- Доступные типы для primary_key - uint8, uint16, uint32, int64

**Таблица доступных типов данных**
```lua
api.db.types = {
    codes = {
        null       = 0,  -- Ситемный тип, использовать нельзя
        int8       = 1,  -- 8 битное знаковое число
        int16      = 2,  -- 16 битное знаковое число
        int32      = 3,  -- 32 битное знаковое число
        int64      = 4,  -- 64 битное знаковое число
        uint8      = 5,  -- 8 битное беззнаковое число
        uint16     = 6,  -- 16 битное беззнаковое число
        uint32     = 7,  -- 32 битное беззнаковое число
        string     = 8,  -- Строка
        norm8      = 9,  -- 8 битное дробное число от -1 до 1
        norm16     = 10, -- 16 битное дробное число от -1 до 1
        float32    = 11, -- 32 битное дробное число
        float64    = 12, -- 64 битное дробное число
        bool       = 13  -- 8 битное True/False
    },

    indexes = {
        [0] = "null",   -- код 0
        "int8",         -- код 1
        "int16",        -- код 2
        "int32",        -- код 3
        "int64",        -- код 4
        "uint8",        -- код 5
        "uint16",       -- код 6
        "uint32",       -- код 7
        "string",       -- код 8
        "norm8",        -- код 9
        "norm16",       -- код 10
        "float32",      -- код 11
        "float64",      -- код 12
        "bool"          -- код 13
    }
}
```

### Коды:
```lua
"Success": 200,
"DatabaseExists" : 101,
"DatabaseNotExists": 102,
"TableExists": 201
```


## Session:

Перед использованием таблиц надо их проинициализировать (Даже если они уже были созданы):
```lua
local Column = api.db.items.Column 
Session:init_table({ 
	__tablename__ = "users", 
	id = Column("uint32", {primary_key = true}), 
	name = Column("string"), 
	hp = Column("uint8")
	saturation = Column("uint8")
})
-- Если таблица не существует - он её создаст
-- В таблице обязательно должа быть колонка primary_key и ТОЛЬКО одна
```

### Методы запросов

#### `:order_by(field, [Необязательный] reverse: Boolean)`
Сортирует результаты по указанному полю.

**Параметры:**
- `field` - имя поля для сортировки
- `reverse` (необязательный) - если true, сортирует в обратном порядке

**Пример:**
```lua
:order_by("hp", true)  -- Сортировка по здоровью в обратном порядке
```

#### `:first()`
Возвращает первый элемент из результатов запроса.

- **Пример:**
```lua
local x = session:query("users")
    :order_by("hp")
    :first()
```

#### `:last()`
Возвращает последний элемент из результатов запроса.

- **Пример:**
```lua
local x = session:query("users")
    :order_by("hp")
    :last()
```

#### `:all()`
Возвращает все элементы из результатов запроса

- **Пример:**
```lua
local x = session:query("users")
    :order_by("hp")
    :all()
```

#### `:count()`
Возвращает кол-во элементов из результата запроса

- **Пример:**
```lua
local x = session:query("users")
    :filter({hp = {[">="] = 15}})
    :count()
```

#### Полный пример запроса
```lua
local results = session:query("users")
    :filter({hp = {[">="] = 15}})
    :filter({name = {["not_in"] = {"Jeremy", "Mark"} }})
    :order_by("hp", true)  -- Сортировка по hp
    :limit(10) -- Лимит значений
    :all()

-- Вернёт 10 первых значений, хп у которых >= 15 и имя не является Jeremy или Mark
-- Полученные значения будут отсортированы по hp в обратном порядке
``` 

## CRUD операции

### Добавление данных
```lua
session:add("users", {
	-- id = 1 -- primary_key не указывается
    name = "Mops",
    hp = 20
})
```

### Обновление данных
```lua
session:update("users", primary_key_value, {
	-- id = 1 -- primary_key не указывается
    name = "Новое имя",
    hp = 10
})
```

### Удаление данных
```lua
session:delete("users", {
    {id = 1},  -- Удалить запись с id=1
    {id = 2}   -- Удалить запись с id=2
})

Очистит всю таблицу, если передана пустая таблица со значениями
```

### Удаление таблицы
```lua
session:remove_table("users")
```


## Особенности
- Методы выбрасывают ошибки при нарушении условий (отсутствие таблицы, неверный primary_key и т.д.)
- Фильтрация поддерживает операторы: `==`, `~=`, `>`, `<`, `>=`, `<=`, `in`, `not_in`
