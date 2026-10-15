from sqlalchemy.orm import sessionmaker, scoped_session, declarative_base
from sqlalchemy import create_engine, event
from contextlib import contextmanager
import os

from api.utils.settings import BASE_DIR


from decouple import config as decouple_config

db_url_env = decouple_config('DB_URL', default=None)
if db_url_env and db_url_env.strip():
    DATABASE_URL = db_url_env
else:
    DATABASE_URL = f"sqlite:///{os.path.join(BASE_DIR, 'atlas.db')}"


def get_db_engine():
    if DATABASE_URL.startswith("sqlite"):
        eng = create_engine(
            DATABASE_URL,
            connect_args={"check_same_thread": False, "timeout": 15},
        )

        @event.listens_for(eng, "connect")
        def set_sqlite_pragma(dbapi_connection, connection_record):
            cursor = dbapi_connection.cursor()
            try:
                cursor.execute("PRAGMA foreign_keys=ON")
                cursor.execute("PRAGMA journal_mode=WAL")
                cursor.execute("PRAGMA synchronous=NORMAL")
                cursor.execute("PRAGMA busy_timeout=5000")
            finally:
                cursor.close()

        return eng

    return create_engine(
        DATABASE_URL,
        pool_pre_ping=True,
        pool_size=10,
        max_overflow=20,
        pool_recycle=1800,
    )

engine = get_db_engine()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

db_session = scoped_session(SessionLocal)

Base = declarative_base()

def create_database():
    import api.v1.models  # Ensure all models are registered on Base.metadata
    return Base.metadata.create_all(bind=engine)

def get_db():
    db = db_session()
    try:
        yield db
    finally:
        db.close()

@contextmanager
def get_db_with_ctx_manager():
    db = db_session()
    try:
        yield db
    finally:
        db.close()
