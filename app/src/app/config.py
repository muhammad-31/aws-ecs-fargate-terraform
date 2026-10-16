"""Runtime configuration, read once from environment variables.

In ECS the plain values come from the task definition and the database
credentials are injected from Secrets Manager (DB_USER / DB_PASSWORD).
"""

from dataclasses import dataclass
import os

from psycopg.conninfo import make_conninfo


@dataclass(frozen=True)
class Settings:
    app_env: str
    app_version: str
    log_level: str
    db_host: str | None
    db_port: int
    db_name: str
    db_user: str | None
    db_password: str | None
    db_sslmode: str

    @property
    def database_configured(self) -> bool:
        return bool(self.db_host and self.db_user and self.db_password)

    @property
    def database_conninfo(self) -> str:
        # make_conninfo quotes values, so generated passwords with spaces,
        # quotes or backslashes still produce a valid connection string.
        return make_conninfo(
            host=self.db_host,
            port=self.db_port,
            dbname=self.db_name,
            user=self.db_user,
            password=self.db_password,
            sslmode=self.db_sslmode,
            connect_timeout=3,
        )


def load_settings() -> Settings:
    return Settings(
        app_env=os.getenv("APP_ENV", "local"),
        app_version=os.getenv("APP_VERSION", "dev"),
        log_level=os.getenv("LOG_LEVEL", "info"),
        db_host=os.getenv("DB_HOST"),
        db_port=int(os.getenv("DB_PORT", "5432")),
        db_name=os.getenv("DB_NAME", "app"),
        db_user=os.getenv("DB_USER"),
        db_password=os.getenv("DB_PASSWORD"),
        db_sslmode=os.getenv("DB_SSLMODE", "prefer"),
    )
