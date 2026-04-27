from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="My VPN API")

# Это нужно чтобы Flutter мог обращаться к серверу без ошибок CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# Модели данных (Pydantic)

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
    ping: int            # в миллисекундах
    configs: list[ServerConfig]


# --- Данные серверов ---
# пока здесь, потом в базу данных

SERVERS: list[VpnServer] = [
    VpnServer(
        id="server-fi-1",
        name="Finland",
        location="Helsinki",
        flagUrl="https://flagcdn.com/w80/fi.png",
        ip="9.10.11.12",
        ping=35,
        configs=[
            ServerConfig(
                protocol="vless",
                config_string="vless://00000000-0000-0000-0000-000000000001@9.10.11.12:443?encryption=none&security=tls&type=ws&path=%2Fvless#Finland",
                priority=1,
            )
        ],
    ),
    VpnServer(
        id="server-de-1",
        name="Germany",
        location="Frankfurt",
        flagUrl="https://flagcdn.com/w80/de.png",
        ip="1.2.3.4",
        ping=45,
        configs=[
            ServerConfig(
                protocol="vless",
                config_string="vless://00000000-0000-0000-0000-000000000002@1.2.3.4:443?encryption=none&security=tls&type=ws&path=%2Fvless#Germany",
                priority=1,
            ),
            ServerConfig(
                protocol="shadowsocks",
                config_string="ss://Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNTpwYXNzd29yZA==@1.2.3.4:8388#Germany-SS",
                priority=2,
            ),
        ],
    ),
    VpnServer(
        id="server-nl-1",
        name="Netherlands",
        location="Amsterdam",
        flagUrl="https://flagcdn.com/w80/nl.png",
        ip="5.6.7.8",
        ping=60,
        configs=[
            ServerConfig(
                protocol="vless",
                config_string="vless://00000000-0000-0000-0000-000000000003@5.6.7.8:443?encryption=none&security=tls&type=ws&path=%2Fvless#Netherlands",
                priority=1,
            )
        ],
    ),
    VpnServer(
        id="server-us-1",
        name="United States 🇺🇸",
        location="New York",
        flagUrl="https://flagcdn.com/w80/us.png",
        ip="13.14.15.16",
        ping=120,
        configs=[
            ServerConfig(
                protocol="vless",
                config_string="vless://00000000-0000-0000-0000-000000000004@13.14.15.16:443?encryption=none&security=tls&type=ws&path=%2Fvless#USA",
                priority=1,
            )
        ],
    ),
]


# --- Эндпоинты ---

@app.get("/")
def root():
    """Просто проверка что сервер живой"""
    return {"status": "ok", "message": "VPN API работает!"}


@app.get("/servers", response_model=list[VpnServer])
def get_servers():
    """Возвращает список всех серверов"""
    print(f"[GET /servers] Клиент запросил список серверов ({len(SERVERS)} шт.)")
    return SERVERS


@app.get("/servers/best", response_model=VpnServer)
def get_best_server():
    """Возвращает сервер с наименьшим пингом"""
    best = min(SERVERS, key=lambda s: s.ping)
    print(f"[GET /servers/best] Лучший сервер: {best.name} ({best.ping} ms)")
    return best


# Запуск: uvicorn main:app --reload
