from .controllers.photo_controller import PhotoController
from .db.sqlite_gateway import SQLiteGateway
from .repos.photo_repository import PhotoRepository
from .services.photo_service import PhotoService


def get_photo_controller() -> PhotoController:
    db = SQLiteGateway()
    photo_repo = PhotoRepository(db)
    photo_service = PhotoService(photo_repo)
    return PhotoController(photo_service)
