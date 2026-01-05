"""
Jiwar Backend - Configuration Settings
Loads environment variables with 8 database support
"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # 8 Database URLs - defaults are placeholders, actual values come from .env
    users_db_url: str
    doctors_db_url: str
    pharmacies_db_url: str
    codes_db_url: str
    restaurants_db_url: str
    companies_db_url: str
    engineers_db_url: str
    mechanics_db_url: str
    teachers_db_url: str
    
    # JWT Settings
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    
    # App Settings
    app_name: str = "Jiwar"
    debug: bool = True
    
    # Email Settings
    mail_username: str | None = None
    mail_password: str | None = None
    support_email: str = "ahmedmohamed1442006m@gmail.com"  # Default, override in .env
    
    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


settings = get_settings()
