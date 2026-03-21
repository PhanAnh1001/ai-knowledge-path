from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "AI Wisdom Battle — Adaptive Engine"
    app_version: str = "0.1.0"
    debug: bool = False

    # Internal service communication
    java_service_url: str = "http://localhost:8080"
    internal_api_key: str = "dev-internal-key"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
