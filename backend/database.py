# backend/database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# подключение к бд
SQLALCHEMY_DATABASE_URL = "sqlite:///./vpn_database.db"

# Инициализация движка SQLAlchemy
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, 
    connect_args={"check_same_thread": False}
)

# Фабрика сессий БД
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Базовый класс для моделей таблиц
Base = declarative_base()
