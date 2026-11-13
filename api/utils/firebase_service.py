import os
from typing import Optional, List
from fastapi import UploadFile
from sqlalchemy.orm import Session
from decouple import config
import firebase_admin
from firebase_admin import credentials, storage, firestore

from firebase_config import firebase_config
from api.v1.models.document import Document
from api.v1.services.document import DocumentService
from api.utils.loggers import create_logger


logger = create_logger(__name__)

class FirebaseService:
    _instance = None

    def __init__(self):
        self.bucket = None
        service_account_path = config("FIREBASE_SERVICE_ACCOUNT", default="serviceAccount.json")
        try:
            if not firebase_admin._apps:
                if os.path.exists(service_account_path):
                    cred = credentials.Certificate(service_account_path)
                    firebase_admin.initialize_app(cred, firebase_config)
                else:
                    logger.warning(f"Firebase credentials not found at '{service_account_path}'. Cloud storage upload disabled.")
            if firebase_admin._apps:
                self.bucket = storage.bucket()
        except Exception as e:
            logger.warning(f"Failed to initialize Firebase Admin SDK: {e}. Cloud storage upload disabled.")

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            try:
                cls._instance = cls()
            except Exception as e:
                logger.warning(f"Could not instantiate FirebaseService: {e}")
                return None
        return cls._instance

    @classmethod
    async def upload_document(
        cls,
        db: Session,
        file: UploadFile,
        title: str,
        project_id: str,
        uploaded_by: str,
        description: Optional[str] = None,
        milestone_id: Optional[str] = None,
        allowed_extensions: Optional[List[str]] = None,
    ) -> Document:
        """Upload a document locally via DocumentService, then push to Firebase Storage."""

        # Step 1: Save locally & create Document record
        document = await DocumentService.upload_document(
            db=db,
            file=file,
            title=title,
            project_id=project_id,
            uploaded_by=uploaded_by,
            description=description,
            milestone_id=milestone_id,
            allowed_extensions=allowed_extensions,
        )

        # Step 2: Push to Firebase Storage
        try:
            instance = cls.get_instance()
            if instance and instance.bucket:
                app_name = config("APP_NAME", default="ATLAS")
                firebase_path = f"{app_name}/projects/{project_id}/documents/{document.file_name}"

                blob = instance.bucket.blob(firebase_path)
                blob.upload_from_filename(document.file_path)
                download_url = blob.public_url

                # Update document with the Firebase download URL
                Document.update(db=db, id=document.id, file_url=download_url)
                document.file_url = download_url

                logger.info(f"Document uploaded to Firebase: {firebase_path}")
        except Exception as e:
            logger.error(f"Firebase upload failed (local copy preserved): {e}")
            # Document still exists locally even if Firebase fails

        return document
