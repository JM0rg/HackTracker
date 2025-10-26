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


def validate_player_name(name, field_name="name"):
    """
    Validate player name (first or last name)
    
    Rules:
    - One word only (no spaces)
    - Letters, hyphens, apostrophes, periods, and accented characters allowed
    - 1-30 characters
    - Trims whitespace
    
    Examples of valid names:
    - "Smith-Jones" (hyphenated)
    - "O'Malley" (apostrophe)
    - "J.R." (periods)
    - "José" (accented characters)
    
    Args:
        name (str): Player name to validate
        field_name (str): Name of the field (for error messages)
        
    Returns:
        str: Cleaned name
        
    Raises:
        ValueError: If validation fails
    """
    if not name or not isinstance(name, str):
        raise ValueError(f"{field_name} must be a non-empty string")
    
    # Trim whitespace
    name = name.strip()
    
    # Check if empty after trimming
    if not name:
        raise ValueError(f"{field_name} must not be empty")
    
    # Check for spaces (must be one word)
    if ' ' in name:
        raise ValueError(f"{field_name} must be a single word (no spaces)")
    
    # Check length
    if len(name) < 1:
        raise ValueError(f"{field_name} must be at least 1 character")
    
    if len(name) > 30:
        raise ValueError(f"{field_name} must not exceed 30 characters")
    
    # Check allowed characters
    # Allow: letters (including Unicode), hyphens, apostrophes, and periods
    # \p{L} matches any Unicode letter (including accented characters)
    # However, Python's re module doesn't support \p{L}, so we use a more permissive pattern
    # that allows letters, hyphens, apostrophes, periods, and common accented characters
    if not re.match(r"^[A-Za-zÀ-ÿ'\.\-]+$", name):
        raise ValueError(f"{field_name} must contain only letters, hyphens, apostrophes, or periods")
    
    return name


def validate_player_number(number):
    """
    Validate player number
    
    Rules:
    - Must be integer between 0 and 99
    
    Args:
        number (int or str): Player number to validate
        
    Returns:
        int: Validated player number
        
    Raises:
        ValueError: If validation fails
    """
    # Try to convert to int if string
    try:
        number = int(number)
    except (TypeError, ValueError):
        raise ValueError("playerNumber must be a valid integer")
    
    # Check range
    if number < 0 or number > 99:
        raise ValueError("playerNumber must be between 0 and 99")
    
    return number


def validate_player_status(status):
    """
    Validate player status
    
    Rules:
    - Must be one of: active, inactive, sub
    - Defaults to 'active' if None or empty
    
    Args:
        status (str or None): Player status
        
    Returns:
        str: Validated status (defaults to 'active')
        
    Raises:
        ValueError: If validation fails
    """
    # Default to 'active' if not provided
    if status is None or status == '':
        return 'active'
    
    if not isinstance(status, str):
        raise ValueError("status must be a string")
    
    # Normalize to lowercase
    status = status.strip().lower()
    
    # Check valid values
    valid_statuses = ['active', 'inactive', 'sub']
    if status not in valid_statuses:
        raise ValueError(f"status must be one of: {', '.join(valid_statuses)}")
    
    return status

