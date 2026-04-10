# backend/models.py
from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class DBServer(Base):
    __tablename__ = "servers"

    id = Column(String, primary_key=True, index=True)
    name = Column(String)
    location = Column(String)
    flagUrl = Column(String)
    ip = Column(String)
    ping = Column(Integer)

    # Связь сервера с конфигурациями
    configs = relationship("DBConfig", back_populates="server")

class DBConfig(Base):
    __tablename__ = "configs"

    id = Column(Integer, primary_key=True, index=True)
    server_id = Column(String, ForeignKey("servers.id"))
    protocol = Column(String)
    config_string = Column(String)
    priority = Column(Integer)

    # Обратная связь с сервером
    server = relationship("DBServer", back_populates="configs")
