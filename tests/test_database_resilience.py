import pytest
from sqlalchemy import text
from api.db.database import get_db_engine

def test_sqlite_engine_pragmas_configured():
    """Verify that get_db_engine configures SQLite WAL, foreign keys, and synchronous pragmas."""
    engine = get_db_engine()
    with engine.connect() as conn:
        fk_result = conn.execute(text("PRAGMA foreign_keys;")).scalar()
        assert fk_result == 1, "Foreign keys must be ON"

        wal_result = conn.execute(text("PRAGMA journal_mode;")).scalar()
        assert str(wal_result).lower() == "wal", f"Journal mode should be WAL, got {wal_result}"

        busy_timeout = conn.execute(text("PRAGMA busy_timeout;")).scalar()
        assert busy_timeout >= 5000, f"Busy timeout should be at least 5000ms, got {busy_timeout}"
