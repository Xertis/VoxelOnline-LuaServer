Система **events** позволяет обмениваться сообщениями между серверными и клиентскими модами.

1. **Отправка события конкретному клиенту:**
```lua
api.events.tell(pack: string, event: string, client: Client, bytes: table<bytes>)
```
   - Отправляет событие **event** с данными **bytes** моду **pack** на сторону указанного клиента **client**.

2. **Отправка события всем клиентам:**
```lua
api.events.echo(pack: string, event: string, bytes: table<bytes>)
```
   - Отправляет событие **event** с данными **bytes** моду **pack** всем подключённым клиентам.

3. **Регистрация обработчика события:**
```lua
api.events.on(pack: string, event: string, func: function(Client, table<bytes>))
```
   - Регистрирует функцию **func**, которая будет вызвана при получении события **event** от мода **pack**. В функцию передаются данные **bytes** и **Client**, с которого пришло сообщение
