import json
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="My VPN API")

# Разрешаем запросы с любых адресов
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Путь к файлу с серверами — лежит рядом с main.py
SERVERS_FILE = Path(__file__).parent / "servers.json"


# --- Модели данных ---

class ServerConfig(BaseModel):
    protocol: str        # vless, shadowsocks, etc.
    config_string: str   # строка подключения, например vless://uuid@ip:port?...
    priority: int        # чем меньше — тем приоритетнее


class VpnServer(BaseModel):
    id: str
    name: str
    location: str
    flagUrl: str
    ip: str
    ping: int
    configs: list[ServerConfig]


# --- Функция загрузки серверов из файла ---
# Читаем файл при каждом запросе — так изменения в servers.json
# применяются сразу, без перезапуска сервера

def load_servers() -> list[VpnServer]:
    if not SERVERS_FILE.exists():
        print(f"[WARN] Файл {SERVERS_FILE} не найден!")
        return []
    with open(SERVERS_FILE, encoding="utf-8") as f:
        data = json.load(f)
    return [VpnServer(**s) for s in data]


# --- Эндпоинты ---

@app.get("/")
def root():
    return {"status": "ok", "message": "VPN API работает!"}


@app.get("/servers", response_model=list[VpnServer])
def get_servers():
    servers = load_servers()
    print(f"[GET /servers] Отдаём {len(servers)} серверов")
    return servers


@app.get("/servers/best", response_model=VpnServer)
def get_best_server():
    servers = load_servers()
    if not servers:
        raise HTTPException(status_code=404, detail="Нет доступных серверов")
    best = min(servers, key=lambda s: s.ping)
    print(f"[GET /servers/best] Лучший: {best.name} ({best.ping} ms)")
    return best


# Запуск: uvicorn main:app --reload --host 0.0.0.0 --port 8000
