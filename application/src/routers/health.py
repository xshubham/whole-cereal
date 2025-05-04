from fastapi import APIRouter
from ..services.health_service import HealthService

router = APIRouter()

@router.get("/health")
async def health_check():
    return HealthService.check_health()