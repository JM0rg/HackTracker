"""Utility functions for Lambda handlers"""

from utils.dynamodb import get_table
from utils.api_gateway import create_response

__all__ = ['get_table', 'create_response']

