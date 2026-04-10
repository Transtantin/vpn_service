# backend/schemas.py
from pydantic import BaseModel
from typing import List
from enum import Enum

class Protocol(str, Enum):
    VLESS = "vless"
    SHADOWSOCKS = "shadowsocks"
    WIREGUARD = "wireguard"
    FPTN = "fptn"

class ServerConfig(BaseModel):
    protocol: Protocol
    config_string: str 
    priority: int
    
    class Config:
        # Поддержка загрузки данных из ORM моделей
        from_attributes = True

class VpnServer(BaseModel):
    id: str
    name: str
    location: str
    flagUrl: str
    ip: str
    ping: int
    configs: List[ServerConfig] = []
    
    class Config:
        from_attributes = True
