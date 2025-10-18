"""
Structured logging utilities for Lambda functions.

Provides helpers for JSON-formatted logs that are easily queryable in CloudWatch Insights.
"""

import json
from datetime import datetime, timezone
from typing import Dict, Any, Optional


def log_event(event_name: str, **kwargs: Any) -> None:
    """
    Log a structured event as JSON.
    
    Args:
        event_name: Name of the event (e.g., 'user_created', 'team_updated')
        **kwargs: Additional fields to include in the log entry
        
    Example:
        log_event('team_created', team_id='TEAM#123', user_id='USER#456', member_count=1)
    """
    log_entry = {
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'event': event_name,
        **kwargs
    }
    print(json.dumps(log_entry))


def log_error(error_type: str, message: str, **kwargs: Any) -> None:
    """
    Log a structured error as JSON.
    
    Args:
        error_type: Type of error (e.g., 'ValidationError', 'DatabaseError')
        message: Error message
        **kwargs: Additional context fields
        
    Example:
        log_error('ValidationError', 'Team name is required', user_id='USER#123')
    """
    log_entry = {
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'level': 'ERROR',
        'error_type': error_type,
        'message': message,
        **kwargs
    }
    print(json.dumps(log_entry))


def log_metric(metric_name: str, value: float, unit: str = 'Count', **kwargs: Any) -> None:
    """
    Log a metric in a structured format.
    
    Can be used with CloudWatch Logs Metric Filters to create custom metrics.
    
    Args:
        metric_name: Name of the metric (e.g., 'TeamCreated', 'QueryDuration')
        value: Numeric value of the metric
        unit: Unit of measurement (Count, Milliseconds, etc.)
        **kwargs: Additional dimensions
        
    Example:
        log_metric('QueryDuration', 145.2, 'Milliseconds', operation='list_teams')
    """
    log_entry = {
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'metric': metric_name,
        'value': value,
        'unit': unit,
        **kwargs
    }
    print(json.dumps(log_entry))

