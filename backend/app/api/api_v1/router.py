from fastapi import APIRouter
from app.api.api_v1.handlers import jumper_api_v1
from app.api.auth.jwt import auth_router

router = APIRouter()

router.include_router(auth_router, prefix='/auth', tags=["auth"])
router.include_router(jumper_api_v1.dashboard_router, prefix='/insight', tags=["insight"])
