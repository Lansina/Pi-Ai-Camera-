from pydantic import BaseModel


class PhotoItem(BaseModel):
    id: int
    timestamp: int
    path: str
    thumb: str | None = None


class DeletePhotoResponse(BaseModel):
    success: bool
    id: int
