# backend/main.py
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware
from typing import List

import models
import schemas
from database import SessionLocal, engine

# Автоматическое создание таблиц при запуске
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="VPN Management API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def create_initial_data(db: Session):
    if db.query(models.DBServer).count() == 0:
        new_server = models.DBServer(
            id="1",
            name="Premium RU",
            location="Russia, Moscow",
            flagUrl="https://flagcdn.com/w80/ru.png",
            ip="192.168.1.100",
            ping=25
        )
        db.add(new_server)
        
        conf1 = models.DBConfig(server_id="1", protocol=schemas.Protocol.VLESS.value, config_string="vless://mock_uuid@192.168.1.100:443?security=reality", priority=100)
        db.add(conf1)
        db.commit()

@app.on_event("startup")
def on_startup():
    db = SessionLocal()
    create_initial_data(db)
    db.close()

@app.get("/servers", response_model=List[schemas.VpnServer])
def get_servers(db: Session = Depends(get_db)):
    return db.query(models.DBServer).all()
