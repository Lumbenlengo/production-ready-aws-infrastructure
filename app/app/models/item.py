# app/models/item.py
from pydantic import BaseModel
from typing import Optional

class Item(BaseModel):
    """Item model for DynamoDB"""
    name: str
    description: Optional[str] = None