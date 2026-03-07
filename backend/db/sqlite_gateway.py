import sqlite3
from contextlib import contextmanager

from ... import database as legacy_db


class SQLiteGateway:
    def __init__(self, db_path: str | None = None):
        self._db_path = db_path or str(legacy_db.DB_PATH)

    @contextmanager
    def connection(self):
        conn = sqlite3.connect(self._db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        finally:
            conn.close()
