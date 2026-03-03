from pathlib import Path

from fastapi import HTTPException

from ..services.photo_service import PhotoService


class PhotoController:
    def __init__(self, photo_service: PhotoService):
        self._photo_service = photo_service

    def list_photos(self, limit: int) -> list[dict]:
        if limit <= 0:
            raise HTTPException(status_code=400, detail="limit must be > 0")
        return self._photo_service.list_photos(limit=limit)

    def delete_photo(self, photo_id: int) -> dict:
        result = self._photo_service.delete_photo(photo_id)
        if not result["deleted"]:
            raise HTTPException(status_code=404, detail="Photo not found")
        return result

    def cleanup_photo_files(self, path: str) -> None:
        photo_path = Path(path)
        if not photo_path.exists():
            return

        try:
            photo_path.unlink()
            thumb_path = photo_path.parent / "thumbs" / photo_path.name
            if thumb_path.exists():
                thumb_path.unlink()
        except Exception as ex:
            raise HTTPException(status_code=500, detail=f"File cleanup failed: {ex}")
