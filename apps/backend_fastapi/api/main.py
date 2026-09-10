from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.v1.router import api_router
from core.config import get_settings
from core.di import container


@asynccontextmanager
async def lifespan(app: FastAPI):
    container.wire()
    yield
    container.unwire()


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="CONFIDIA - Hub numérique intelligent",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type", "Accept", "Accept-Language"],
    )

    @app.middleware("http")
    async def security_headers(request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers.setdefault("Cache-Control", "no-store")
        return response

    app.include_router(api_router, prefix="/api/v1")

    @app.get("/health")
    async def health():
        return {"status": "healthy", "version": settings.app_version}

    return app


app = create_app()
