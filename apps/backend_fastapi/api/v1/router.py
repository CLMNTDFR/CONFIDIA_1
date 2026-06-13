from fastapi import APIRouter

from api.v1 import access_control, ai, auth, calendar, documents, notifications, storage, users

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(documents.router, prefix="/documents", tags=["Documents"])
api_router.include_router(calendar.router, prefix="/calendar", tags=["Calendar"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
api_router.include_router(storage.router, prefix="/storage", tags=["Storage"])
api_router.include_router(ai.router, prefix="/ai", tags=["AI"])
api_router.include_router(access_control.router, prefix="/access-control", tags=["Access Control"])
