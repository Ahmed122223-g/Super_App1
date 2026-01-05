"""
Jiwar Backend - Multi-Database Configuration
Manages 8 database connections using psycopg3 driver
"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import settings


def get_db_url(url: str) -> str:
    """Convert postgresql:// to postgresql+psycopg:// for psycopg3"""
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+psycopg://", 1)
    return url


# ============================================
# DATABASE ENGINES (8 Databases)
# ============================================

# 1. Users Database
users_engine = create_engine(
    get_db_url(settings.users_db_url),
    pool_pre_ping=True,
    pool_size=2, # Reduced from 10 to save resources (8 DBs * 2 connections = 16 min)
    max_overflow=5 # Reduced from 20
)
UsersSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=users_engine)
UsersBase = declarative_base()

# 2. Doctors Database
doctors_engine = create_engine(
    get_db_url(settings.doctors_db_url),
    pool_pre_ping=True,
    pool_size=2, # Reduced from 10 to save resources (8 DBs * 2 connections = 16 min)
    max_overflow=5 # Reduced from 20
)
DoctorsSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=doctors_engine)
DoctorsBase = declarative_base()

# 3. Pharmacies Database
pharmacies_engine = create_engine(
    get_db_url(settings.pharmacies_db_url),
    pool_pre_ping=True,
    pool_size=2, # Reduced from 10 to save resources (8 DBs * 2 connections = 16 min)
    max_overflow=5 # Reduced from 20
)
PharmaciesSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=pharmacies_engine)
PharmaciesBase = declarative_base()

# 4. Registration Codes Database
codes_engine = create_engine(
    get_db_url(settings.codes_db_url),
    pool_pre_ping=True,
    pool_size=2,
    max_overflow=5
)
CodesSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=codes_engine)
CodesBase = declarative_base()

# 5. Restaurants Database (Future)
restaurants_engine = create_engine(
    get_db_url(settings.restaurants_db_url),
    pool_pre_ping=True,
    pool_size=2, # Reduced from 10 to save resources (8 DBs * 2 connections = 16 min)
    max_overflow=5 # Reduced from 20
)
RestaurantsSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=restaurants_engine)
RestaurantsBase = declarative_base()

# 6. Companies Database (Future)
companies_engine = create_engine(
    get_db_url(settings.companies_db_url),
    pool_pre_ping=True,
    pool_size=2, # Reduced from 10 to save resources (8 DBs * 2 connections = 16 min)
    max_overflow=5 # Reduced from 20
)
CompaniesSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=companies_engine)
CompaniesBase = declarative_base()

# 7. Engineers Database (Future)
engineers_engine = create_engine(
    get_db_url(settings.engineers_db_url),
    pool_pre_ping=True,
    pool_size=2, # Reduced from 10 to save resources (8 DBs * 2 connections = 16 min)
    max_overflow=5 # Reduced from 20
)
EngineersSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engineers_engine)
EngineersBase = declarative_base()

# 8. Mechanics Database (Future)
mechanics_engine = create_engine(
    get_db_url(settings.mechanics_db_url),
    pool_pre_ping=True,
    pool_size=2, # Reduced from 10 to save resources (8 DBs * 2 connections = 16 min)
    max_overflow=5 # Reduced from 20
)
MechanicsSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=mechanics_engine)
MechanicsSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=mechanics_engine)
MechanicsBase = declarative_base()

# 9. Teachers Database
teachers_engine = create_engine(
    get_db_url(settings.teachers_db_url),
    pool_pre_ping=True,
    pool_size=2, # Reduced from 10 to save resources (8 DBs * 2 connections = 16 min)
    max_overflow=5 # Reduced from 20
)
TeachersSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=teachers_engine)
TeachersBase = declarative_base()


# ============================================
# DATABASE DEPENDENCIES
# ============================================

def get_users_db():
    """Dependency for Users database session"""
    db = UsersSessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_doctors_db():
    """Dependency for Doctors database session"""
    db = DoctorsSessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_pharmacies_db():
    """Dependency for Pharmacies database session"""
    db = PharmaciesSessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_codes_db():
    """Dependency for Codes database session"""
    db = CodesSessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_restaurants_db():
    """Dependency for Restaurants database session (Future)"""
    db = RestaurantsSessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_companies_db():
    """Dependency for Companies database session (Future)"""
    db = CompaniesSessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_engineers_db():
    """Dependency for Engineers database session (Future)"""
    db = EngineersSessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_mechanics_db():
    """Dependency for Mechanics database session (Future)"""
    db = MechanicsSessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_teachers_db():
    """Dependency for Teachers database session"""
    db = TeachersSessionLocal()
    try:
        yield db
    finally:
        db.close()


# ============================================
# INITIALIZE ALL DATABASES
# ============================================

def init_all_databases():
    """Create all tables in all databases"""
    from app.models.user import User
    from app.models.doctor import Doctor, Specialty, DoctorRating
    from app.models.pharmacy import Pharmacy, Medicine, PharmacyRating
    from app.models.codes import (
        DoctorCode, PharmacyCode, RestaurantCode,
        CompanyCode, EngineerCode, MechanicCode, TeacherCode
    )
    
    # Create tables in active databases
    UsersBase.metadata.create_all(bind=users_engine)
    DoctorsBase.metadata.create_all(bind=doctors_engine)
    PharmaciesBase.metadata.create_all(bind=pharmacies_engine)
    PharmaciesBase.metadata.create_all(bind=pharmacies_engine)
    CodesBase.metadata.create_all(bind=codes_engine)
    
    # Initialize Teachers tables (will fail if model not imported, but imports are inside function)
    # We need to make sure Teacher model is imported inside init_all_databases or before
    try:
        from app.models.teacher import Teacher, Subject
        TeachersBase.metadata.create_all(bind=teachers_engine)
    except ImportError:
        pass
    
    print("✅ All databases initialized")


# Legacy support
Base = UsersBase
engine = users_engine
SessionLocal = UsersSessionLocal
get_db = get_users_db
