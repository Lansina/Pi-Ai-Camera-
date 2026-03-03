from fastapi import APIRouter, Depends

from ..controllers.photo_controller import PhotoController
from ..dependencies import get_photo_controller
from ..schemas.photo_schema import DeletePhotoResponse, PhotoItem

router = APIRouter(prefix="/api/v2/photos", tags=["photos-v2"])


@router.get("", response_model=list[PhotoItem])
def list_photos(
    limit: int = 100,
    controller: PhotoController = Depends(get_photo_controller),
):
    return controller.list_photos(limit=limit)


@router.delete("/{photo_id}", response_model=DeletePhotoResponse)
def delete_photo(
    photo_id: int,
    controller: PhotoController = Depends(get_photo_controller),
):
    result = controller.delete_photo(photo_id)
    if result["path"]:
        controller.cleanup_photo_files(result["path"])
    return {"success": True, "id": photo_id}
