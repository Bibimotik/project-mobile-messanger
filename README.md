Swagger UI интерфейс(через него отправлять запросы):

```
open http://localhost:8080/docs
```

Развернуть docker контейнеры
```
docker-compose up -d --build
```

Снести контейнеры
```
docker-compose down
```

Вывести данные таблиц
```
docker exec -it postgres_db psql -U postgres -d mydatabase -c "SELECT * FROM users;"

```