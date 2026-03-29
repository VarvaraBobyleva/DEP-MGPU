from pymongo import MongoClient

# Подключаемся к MongoDB (она уже должна быть запущена в Docker)
client = MongoClient('mongodb://localhost:27017/')
db = client['streaming_db']

# 1. Наполняем каталог контента (фильмы)
movies_data = [
    {"movie_id": 101, "title": "Inception", "genre": "Sci-Fi", "is_bw": False, "rating": 8.8},
    {"movie_id": 102, "title": "Schindler's List", "genre": "Drama", "is_bw": True, "rating": 9.0},
    {"movie_id": 103, "title": "The Artist", "genre": "Comedy", "is_bw": True, "rating": 7.9},
    {"movie_id": 104, "title": "Interstellar", "genre": "Sci-Fi", "is_bw": False, "rating": 8.6},
    {"movie_id": 105, "title": "The Lighthouse", "genre": "Horror", "is_bw": True, "rating": 7.5},
    {"movie_id": 106, "title": "Pulp Fiction", "genre": "Crime", "is_bw": False, "rating": 8.9},
    {"movie_id": 107, "title": "Psycho", "genre": "Thriller", "is_bw": True, "rating": 8.5},
    {"movie_id": 108, "title": "The Dark Knight", "genre": "Action", "is_bw": False, "rating": 9.0},
    {"movie_id": 109, "title": "Citizen Kane", "genre": "Drama", "is_bw": True, "rating": 8.3},
    {"movie_id": 110, "title": "Mad Max: Fury Road", "genre": "Action", "is_bw": False, "rating": 8.1},
    {"movie_id": 111, "title": "Roma", "genre": "Drama", "is_bw": True, "rating": 7.7},
    {"movie_id": 112, "title": "Seven Samurai", "genre": "Adventure", "is_bw": True, "rating": 8.6}
]

# 2. Наполняем профили пользователей
users_data = [
    {"user_id": 1, "name": "Ivan", "prefs": ["Sci-Fi", "Drama"]},
    {"user_id": 2, "name": "Maria", "prefs": ["Comedy"]}
]

# Очищаем старое (если есть) и записываем новое
db.movies.delete_many({})
db.users.delete_many({})

db.movies.insert_many(movies_data)
db.users.insert_many(users_data)

print("Данные в MongoDB успешно загружены!")
