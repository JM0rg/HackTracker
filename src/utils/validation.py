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


def validate_player_positions(positions):
    """
    Validate player positions
    
    Rules:
    - Must be a list/array
    - Maximum 2 positions allowed
    - Valid positions: 1B, 2B, 3B, SS, OF, C, P, DH, UTIL
    - Positions are case-insensitive but returned in uppercase
    - Duplicates are removed
    
    Args:
        positions: List of position strings to validate
        
    Returns:
        list: Validated and normalized positions array (uppercase, no duplicates)
        
    Raises:
        ValueError: If validation fails
    """
    if positions is None:
        return []
    
    if not isinstance(positions, (list, tuple)):
        raise ValueError("positions must be an array")
    
    # Valid positions
    valid_positions = ['1B', '2B', '3B', 'SS', 'OF', 'C', 'P', 'DH', 'UTIL']
    
    # Normalize and validate each position
    normalized = []
    for pos in positions:
        if not isinstance(pos, str):
            raise ValueError("Each position must be a string")
        
        pos_upper = pos.strip().upper()
        
        if pos_upper not in valid_positions:
            raise ValueError(f"Invalid position '{pos}'. Valid positions: {', '.join(valid_positions)}")
        
        # Add if not already in list (remove duplicates)
        if pos_upper not in normalized:
            normalized.append(pos_upper)
    
    # Check max 2 positions
    if len(normalized) > 2:
        raise ValueError("A player can have a maximum of 2 positions")
    
    return normalized


def validate_game_status(status):
    """
    Validate game status
    
    Rules:
    - Must be one of: SCHEDULED, IN_PROGRESS, FINAL, POSTPONED
    - Defaults to 'SCHEDULED' if None or empty
    
    Args:
        status (str or None): Game status
        
    Returns:
        str: Validated status (defaults to 'SCHEDULED')
        
    Raises:
        ValueError: If validation fails
    """
    # Default to 'SCHEDULED' if not provided
    if status is None or status == '':
        return 'SCHEDULED'
    
    if not isinstance(status, str):
        raise ValueError("status must be a string")
    
    # Normalize to uppercase
    status = status.strip().upper()
    
    # Check valid values
    valid_statuses = ['SCHEDULED', 'IN_PROGRESS', 'FINAL', 'POSTPONED']
    if status not in valid_statuses:
        raise ValueError(f"status must be one of: {', '.join(valid_statuses)}")
    
    return status


def validate_score(score):
    """
    Validate game score
    
    Rules:
    - Must be integer >= 0
    - Can be string that converts to int
    
    Args:
        score (int or str): Score to validate
        
    Returns:
        int: Validated score
        
    Raises:
        ValueError: If validation fails
    """
    # Try to convert to int if string
    try:
        score = int(score)
    except (TypeError, ValueError):
        raise ValueError("Score must be a valid integer")
    
    # Check range
    if score < 0:
        raise ValueError("Score must be 0 or greater")
    
    return score


def validate_team_type(team_type):
    """
    Validate team type
    
    Rules:
    - Must be one of: MANAGED, PERSONAL
    
    Args:
        team_type (str): Team type to validate
        
    Returns:
        str: Validated team type (uppercase)
        
    Raises:
        ValueError: If validation fails
    """
    if not team_type or not isinstance(team_type, str):
        raise ValueError("Team type is required and must be a string")
    
    # Normalize to uppercase
    team_type = team_type.strip().upper()
    
    # Check valid values
    valid_types = ['MANAGED', 'PERSONAL']
    if team_type not in valid_types:
        raise ValueError(f'Team type must be one of: {", ".join(valid_types)}')
    
    return team_type


def validate_lineup(lineup):
    """
    Validate game lineup
    
    Rules:
    - Must be a list
    - Each item must be a dict with 'playerId' and 'battingOrder'
    - playerId must be non-empty string
    - battingOrder must be integer >= 1
    
    Args:
        lineup (list or None): Lineup to validate
        
    Returns:
        list: Validated lineup
        
    Raises:
        ValueError: If validation fails
    """
    if lineup is None:
        return []
    
    if not isinstance(lineup, list):
        raise ValueError("lineup must be a list")
    
    validated_lineup = []
    batting_orders = set()
    
    for i, item in enumerate(lineup):
        if not isinstance(item, dict):
            raise ValueError(f"lineup item {i} must be a dictionary")
        
        # Check required fields
        if 'playerId' not in item:
            raise ValueError(f"lineup item {i} missing 'playerId' field")
        
        if 'battingOrder' not in item:
            raise ValueError(f"lineup item {i} missing 'battingOrder' field")
        
        # Validate playerId
        player_id = item['playerId']
        if not isinstance(player_id, str) or not player_id.strip():
            raise ValueError(f"lineup item {i} 'playerId' must be a non-empty string")
        
        # Validate battingOrder
        try:
            batting_order = int(item['battingOrder'])
        except (TypeError, ValueError):
            raise ValueError(f"lineup item {i} 'battingOrder' must be a valid integer")
        
        if batting_order < 1:
            raise ValueError(f"lineup item {i} 'battingOrder' must be 1 or greater")
        
        # Check for duplicate batting orders
        if batting_order in batting_orders:
            raise ValueError(f"Duplicate batting order {batting_order} in lineup")
        
        batting_orders.add(batting_order)
        
        validated_lineup.append({
            'playerId': player_id.strip(),
            'battingOrder': batting_order
        })
    
    return validated_lineup

