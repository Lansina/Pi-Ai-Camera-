from pathlib import Path
from typing import List

from ..repos.photo_repository import PhotoRepository


class PhotoService:
    def __init__(self, photo_repo: PhotoRepository):
        self._photo_repo = photo_repo

    def list_photos(self, limit: int = 100) -> List[dict]:
        rows = self._photo_repo.list_photos(limit=limit)
        out = []
        for row in rows:
            file_name = Path(row["path"]).name
            out.append(
                {
                    "id": row["id"],
                    "timestamp": row["timestamp"],
                    "path": f"/data/photos/{file_name}",
                    "thumb": f"/data/photos/thumbs/{file_name}",
                }
            )
        return out

    def delete_photo(self, photo_id: int) -> dict:
        original_path = self._photo_repo.get_photo_path(photo_id)
        if not original_path:
            return {"deleted": False, "path": None}

        deleted = self._photo_repo.delete_photo(photo_id)
        return {"deleted": deleted, "path": original_path}
