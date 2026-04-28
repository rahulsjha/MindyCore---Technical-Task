from functools import lru_cache

from pydantic import Field, AliasChoices
from pydantic_settings import BaseSettings, SettingsConfigDict


def _normalize_database_url(url: str | None) -> str | None:
    if not url:
        return None
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+psycopg://", 1)
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+psycopg://", 1)
    return url


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "mindy-task"
    jwt_secret_key: str = Field("change-this-secret", validation_alias=AliasChoices("JWT_SECRET_KEY"))
    jwt_algorithm: str = Field("HS256", validation_alias=AliasChoices("JWT_ALGORITHM"))
    access_token_expire_minutes: int = Field(
        60, validation_alias=AliasChoices("ACCESS_TOKEN_EXPIRE_MINUTES")
    )
    database_url: str | None = Field(
        default=None,
        validation_alias=AliasChoices("DATABASE_URL", "DB_URL"),
    )
    db_internal_username: str | None = Field(
        default=None,
        validation_alias=AliasChoices("DB_INTERNALUSERNAME", "DB_INTERNAL_USERNAME"),
    )
    db_external_username: str | None = Field(
        default=None,
        validation_alias=AliasChoices("DB_EXTERNALUSERNAME", "DB_EXTERNAL_USERNAME"),
    )
    db_hostname: str | None = Field(default=None, validation_alias=AliasChoices("DB_HOSTNAME"))
    db_username: str | None = Field(default=None, validation_alias=AliasChoices("DB_USERNAME"))
    db_password: str | None = Field(default=None, validation_alias=AliasChoices("DB_PASSWORD"))
    db_name: str | None = Field(default=None, validation_alias=AliasChoices("DB_NAME"))
    db_port: int = Field(default=5432, validation_alias=AliasChoices("DB_PORT"))

    @property
    def sqlalchemy_database_url(self) -> str:
        direct_url = _normalize_database_url(self.database_url)
        if direct_url:
            return direct_url

        internal_url = _normalize_database_url(self.db_internal_username)
        if internal_url:
            return internal_url

        external_url = _normalize_database_url(self.db_external_username)
        if external_url:
            return external_url

        if self.db_hostname and self.db_username and self.db_password and self.db_name:
            db_name = self.db_name.replace(" ", "_")
            return (
                f"postgresql+psycopg://{self.db_username}:{self.db_password}"
                f"@{self.db_hostname}:{self.db_port}/{db_name}"
            )

        raise ValueError("A database connection URL must be provided through environment variables.")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
