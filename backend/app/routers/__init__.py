"""
Jiwar Backend - Routers Package
"""
from app.routers.auth import router as auth_router
from app.routers.doctors import router as doctors_router
from app.routers.pharmacies import router as pharmacies_router
from app.routers.specialties import router as specialties_router
from app.routers.ratings import router as ratings_router
from app.routers.search import router as search_router
from app.routers.teachers import router as teachers_router
from app.routers.dashboard import router as dashboard_router
from app.routers.addresses import router as addresses_router
from app.routers.notifications import router as notifications_router
from app.routers.utils import router as utils_router
from app.routers.favorites import router as favorites_router

__all__ = [
    "auth_router",
    "doctors_router",
    "pharmacies_router",
    "specialties_router",
    "ratings_router",
    "search_router",
    "teachers_router",
    "dashboard_router",
    "utils_router",
    "favorites_router",
    "addresses_router",
    "notifications_router"
]
