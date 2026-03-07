from typing import List, Optional

from ..db.sqlite_gateway import SQLiteGateway


class PhotoRepository:
    def __init__(self, db: SQLiteGateway):
        self._db = db

    def list_photos(self, limit: int = 100) -> List[dict]:
        with self._db.connection() as conn:
            cur = conn.cursor()
            cur.execute(
                "SELECT id, timestamp, path FROM photos ORDER BY timestamp DESC LIMIT ?",
                (int(limit),),
            )
            return [dict(row) for row in cur.fetchall()]

    def get_photo_path(self, photo_id: int) -> Optional[str]:
        with self._db.connection() as conn:
            cur = conn.cursor()
            cur.execute("SELECT path FROM photos WHERE id = ?", (int(photo_id),))
            row = cur.fetchone()
            if not row:
                return None
            return row["path"]

    def delete_photo(self, photo_id: int) -> bool:
        with self._db.connection() as conn:
            cur = conn.cursor()
            cur.execute("DELETE FROM photos WHERE id = ?", (int(photo_id),))
            return cur.rowcount > 0
