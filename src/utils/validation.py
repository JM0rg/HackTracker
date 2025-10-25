"""
Validation utilities for HackTracker

Provides shared validation functions for team names, descriptions, etc.
"""

import re


def validate_team_name(name):
    """
    Validate and clean team name
    
    Rules:
    - 3-50 characters
    - Letters, numbers, and spaces only
    - Automatically trims whitespace
    - Collapses multiple spaces into single space
    
    Args:
        name (str): Team name to validate
        
    Returns:
        str: Cleaned team name
        
    Raises:
        ValueError: If validation fails
    """
    if not name or not isinstance(name, str):
        raise ValueError("Team name is required and must be a string")
    
    # Remove leading/trailing whitespace
    name = name.strip()
    
    # Collapse multiple spaces into single space
    name = re.sub(r'\s+', ' ', name)
    
    # Check length
    if len(name) < 3:
        raise ValueError("Team name must be at least 3 characters")
    
    if len(name) > 50:
        raise ValueError("Team name must not exceed 50 characters")
    
    # Check allowed characters (letters, numbers, spaces only)
    if not re.match(r'^[a-zA-Z0-9\s]+$', name):
        raise ValueError("Team name can only contain letters, numbers, and spaces")
    
    return name


def validate_team_description(description):
    """
    Validate team description
    
    Rules:
    - Optional field
    - Max 500 characters if provided
    - Trims whitespace
    
    Args:
        description (str or None): Team description
        
    Returns:
        str or None: Cleaned description or None
        
    Raises:
        ValueError: If validation fails
    """
    if description is None or description == '':
        return None
    
    if not isinstance(description, str):
        raise ValueError("Description must be a string")
    
    # Trim whitespace
    description = description.strip()
    
    # Empty after trimming is same as None
    if not description:
        return None
    
    # Check length
    if len(description) > 500:
        raise ValueError("Description must not exceed 500 characters")
    
    return description

