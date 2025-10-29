"""Utility functions for Lambda handlers"""

from .dynamodb import get_table
from .api_gateway import create_response

__all__ = ['get_table', 'create_response']

