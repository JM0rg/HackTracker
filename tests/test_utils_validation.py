"""
Unit tests for src/utils/validation.py

Tests all validation utility functions comprehensively.
"""

import pytest
from src.utils.validation import (
    validate_team_name,
    validate_team_description,
    validate_player_name,
    validate_player_number,
    validate_player_status,
    validate_player_positions,
    validate_game_title,
    validate_game_status,
    validate_score,
    validate_team_type,
    validate_lineup
)


class TestValidateTeamName:
    """Test validate_team_name function"""
    
    def test_valid_team_name(self):
        """Test valid team name"""
        assert validate_team_name("Warriors") == "Warriors"
        assert validate_team_name("Team 123") == "Team 123"
        assert validate_team_name("The Best Team") == "The Best Team"
    
    def test_team_name_trims_whitespace(self):
        """Test that whitespace is trimmed"""
        assert validate_team_name("  Warriors  ") == "Warriors"
        assert validate_team_name("\tTeam\n") == "Team"
    
    def test_team_name_collapses_spaces(self):
        """Test that multiple spaces are collapsed"""
        assert validate_team_name("The    Best    Team") == "The Best Team"
    
    def test_team_name_too_short(self):
        """Test team name too short"""
        with pytest.raises(ValueError, match="at least 3 characters"):
            validate_team_name("AB")
    
    def test_team_name_too_long(self):
        """Test team name too long"""
        with pytest.raises(ValueError, match="must not exceed 50 characters"):
            validate_team_name("A" * 51)
    
    def test_team_name_invalid_characters(self):
        """Test team name with invalid characters"""
        with pytest.raises(ValueError, match="can only contain letters, numbers, and spaces"):
            validate_team_name("Team@123")
        with pytest.raises(ValueError):
            validate_team_name("Team-Name")
        with pytest.raises(ValueError):
            validate_team_name("Team_Name")
    
    def test_team_name_empty_or_none(self):
        """Test empty or None team name"""
        with pytest.raises(ValueError, match="Team name is required"):
            validate_team_name("")
        with pytest.raises(ValueError, match="Team name is required"):
            validate_team_name(None)
    
    def test_team_name_not_string(self):
        """Test team name that's not a string"""
        with pytest.raises(ValueError, match="must be a string"):
            validate_team_name(123)


class TestValidateTeamDescription:
    """Test validate_team_description function"""
    
    def test_valid_description(self):
        """Test valid description"""
        assert validate_team_description("A great team") == "A great team"
    
    def test_description_trims_whitespace(self):
        """Test description trims whitespace"""
        assert validate_team_description("  Description  ") == "Description"
    
    def test_description_empty_returns_none(self):
        """Test empty description returns None"""
        assert validate_team_description("") is None
        assert validate_team_description("   ") is None
        assert validate_team_description(None) is None
    
    def test_description_too_long(self):
        """Test description too long"""
        with pytest.raises(ValueError, match="must not exceed 500 characters"):
            validate_team_description("A" * 501)
    
    def test_description_not_string(self):
        """Test description that's not a string"""
        with pytest.raises(ValueError, match="must be a string"):
            validate_team_description(123)


class TestValidatePlayerName:
    """Test validate_player_name function"""
    
    def test_valid_player_names(self):
        """Test valid player names"""
        assert validate_player_name("Smith") == "Smith"
        assert validate_player_name("O'Malley") == "O'Malley"
        assert validate_player_name("Smith-Jones") == "Smith-Jones"
        assert validate_player_name("J.R.") == "J.R."
        assert validate_player_name("José") == "José"
    
    def test_player_name_trims_whitespace(self):
        """Test player name trims whitespace"""
        assert validate_player_name("  Smith  ") == "Smith"
    
    def test_player_name_with_spaces(self):
        """Test player name with spaces (should fail)"""
        with pytest.raises(ValueError, match="must be a single word"):
            validate_player_name("John Smith")
    
    def test_player_name_too_long(self):
        """Test player name too long"""
        with pytest.raises(ValueError, match="must not exceed 30 characters"):
            validate_player_name("A" * 31)
    
    def test_player_name_empty(self):
        """Test empty player name"""
        with pytest.raises(ValueError, match="must be a non-empty string"):
            validate_player_name("")
        with pytest.raises(ValueError):
            validate_player_name("   ")
    
    def test_player_name_invalid_characters(self):
        """Test player name with invalid characters"""
        with pytest.raises(ValueError, match="must contain only"):
            validate_player_name("Smith@123")
    
    def test_player_name_custom_field_name(self):
        """Test custom field name in error message"""
        with pytest.raises(ValueError, match="firstName"):
            validate_player_name("", field_name="firstName")


class TestValidatePlayerNumber:
    """Test validate_player_number function"""
    
    def test_valid_player_numbers(self):
        """Test valid player numbers"""
        assert validate_player_number(0) == 0
        assert validate_player_number(23) == 23
        assert validate_player_number(99) == 99
    
    def test_player_number_from_string(self):
        """Test player number from string"""
        assert validate_player_number("42") == 42
    
    def test_player_number_out_of_range(self):
        """Test player number out of range"""
        with pytest.raises(ValueError, match="must be between 0 and 99"):
            validate_player_number(-1)
        with pytest.raises(ValueError):
            validate_player_number(100)
    
    def test_player_number_invalid(self):
        """Test invalid player number"""
        with pytest.raises(ValueError, match="must be a valid integer"):
            validate_player_number("abc")
        with pytest.raises(ValueError):
            validate_player_number(None)


class TestValidatePlayerStatus:
    """Test validate_player_status function"""
    
    def test_valid_statuses(self):
        """Test valid player statuses"""
        assert validate_player_status("active") == "active"
        assert validate_player_status("inactive") == "inactive"
        assert validate_player_status("sub") == "sub"
    
    def test_status_case_insensitive(self):
        """Test status is case insensitive"""
        assert validate_player_status("ACTIVE") == "active"
        assert validate_player_status("InActive") == "inactive"
    
    def test_status_defaults_to_active(self):
        """Test status defaults to active"""
        assert validate_player_status(None) == "active"
        assert validate_player_status("") == "active"
    
    def test_status_trims_whitespace(self):
        """Test status trims whitespace"""
        assert validate_player_status("  active  ") == "active"
    
    def test_invalid_status(self):
        """Test invalid status"""
        with pytest.raises(ValueError, match="must be one of"):
            validate_player_status("unknown")
    
    def test_status_not_string(self):
        """Test status not a string"""
        with pytest.raises(ValueError, match="must be a string"):
            validate_player_status(123)


class TestValidatePlayerPositions:
    """Test validate_player_positions function"""
    
    def test_valid_positions(self):
        """Test valid positions"""
        assert validate_player_positions(["1B"]) == ["1B"]
        assert validate_player_positions(["SS", "2B"]) == ["SS", "2B"]
    
    def test_positions_case_insensitive(self):
        """Test positions are case insensitive"""
        assert validate_player_positions(["1b", "ss"]) == ["1B", "SS"]
    
    def test_positions_removes_duplicates(self):
        """Test positions removes duplicates"""
        assert validate_player_positions(["1B", "1B"]) == ["1B"]
        assert validate_player_positions(["ss", "SS"]) == ["SS"]
    
    def test_positions_empty_list(self):
        """Test empty positions list"""
        assert validate_player_positions([]) == []
        assert validate_player_positions(None) == []
    
    def test_positions_too_many(self):
        """Test too many positions"""
        with pytest.raises(ValueError, match="maximum of 2 positions"):
            validate_player_positions(["1B", "2B", "3B"])
    
    def test_positions_invalid(self):
        """Test invalid positions"""
        with pytest.raises(ValueError, match="Invalid position"):
            validate_player_positions(["QB"])
    
    def test_positions_not_list(self):
        """Test positions not a list"""
        with pytest.raises(ValueError, match="must be an array"):
            validate_player_positions("1B")


class TestValidateGameTitle:
    """Test validate_game_title function"""
    
    def test_valid_game_title(self):
        """Test valid game title"""
        assert validate_game_title("Game vs Warriors") == "Game vs Warriors"
    
    def test_game_title_trims_whitespace(self):
        """Test game title trims whitespace"""
        assert validate_game_title("  Game  ") == "Game"
    
    def test_game_title_too_short(self):
        """Test game title too short"""
        with pytest.raises(ValueError, match="at least 3 characters"):
            validate_game_title("AB")
    
    def test_game_title_too_long(self):
        """Test game title too long"""
        with pytest.raises(ValueError, match="must not exceed 100 characters"):
            validate_game_title("A" * 101)
    
    def test_game_title_empty(self):
        """Test empty game title"""
        with pytest.raises(ValueError, match="Game title is required"):
            validate_game_title("")
        with pytest.raises(ValueError):
            validate_game_title(None)


class TestValidateGameStatus:
    """Test validate_game_status function"""
    
    def test_valid_game_statuses(self):
        """Test valid game statuses"""
        assert validate_game_status("scheduled") == "SCHEDULED"
        assert validate_game_status("in_progress") == "IN_PROGRESS"
        assert validate_game_status("FINAL") == "FINAL"
        assert validate_game_status("POSTPONED") == "POSTPONED"
    
    def test_game_status_case_insensitive(self):
        """Test game status is case insensitive"""
        assert validate_game_status("SCHEDULED") == "SCHEDULED"
        assert validate_game_status("scheduled") == "SCHEDULED"
    
    def test_game_status_defaults(self):
        """Test game status defaults to SCHEDULED"""
        assert validate_game_status(None) == "SCHEDULED"
        assert validate_game_status("") == "SCHEDULED"
    
    def test_invalid_game_status(self):
        """Test invalid game status"""
        with pytest.raises(ValueError, match="must be one of"):
            validate_game_status("unknown")


class TestValidateScore:
    """Test validate_score function"""
    
    def test_valid_scores(self):
        """Test valid scores"""
        assert validate_score(0) == 0
        assert validate_score(5) == 5
        assert validate_score(50) == 50
    
    def test_score_from_string(self):
        """Test score from string"""
        assert validate_score("10") == 10
    
    def test_score_negative(self):
        """Test negative score"""
        with pytest.raises(ValueError, match="must be 0 or greater"):
            validate_score(-1)
    
    def test_score_invalid(self):
        """Test invalid score"""
        with pytest.raises(ValueError, match="must be a valid integer"):
            validate_score("abc")
    
    def test_score_none(self):
        """Test None score raises ValueError"""
        with pytest.raises(ValueError, match="must be a valid integer"):
            validate_score(None)


class TestValidateTeamType:
    """Test validate_team_type function"""
    
    def test_valid_team_types(self):
        """Test valid team types"""
        assert validate_team_type("MANAGED") == "MANAGED"
        assert validate_team_type("PERSONAL") == "PERSONAL"
    
    def test_team_type_case_insensitive(self):
        """Test team type is case insensitive"""
        assert validate_team_type("managed") == "MANAGED"
        assert validate_team_type("personal") == "PERSONAL"
    
    def test_team_type_requires_value(self):
        """Test team type requires a value"""
        with pytest.raises(ValueError, match="Team type is required"):
            validate_team_type(None)
        with pytest.raises(ValueError, match="Team type is required"):
            validate_team_type("")
    
    def test_invalid_team_type(self):
        """Test invalid team type"""
        with pytest.raises(ValueError, match="must be one of"):
            validate_team_type("UNKNOWN")


class TestValidateLineup:
    """Test validate_lineup function"""
    
    def test_valid_lineup(self):
        """Test valid lineup"""
        lineup = [
            {"playerId": "player-1", "battingOrder": 1, "position": "1B"},
            {"playerId": "player-2", "battingOrder": 2, "position": "SS"}
        ]
        result = validate_lineup(lineup)
        assert len(result) == 2
        assert result[0]["battingOrder"] == 1
    
    def test_lineup_empty(self):
        """Test empty lineup"""
        assert validate_lineup([]) == []
        assert validate_lineup(None) == []
    
    def test_lineup_not_list(self):
        """Test lineup not a list"""
        with pytest.raises(ValueError, match="must be a list"):
            validate_lineup("not a list")
    
    def test_lineup_invalid_player(self):
        """Test lineup with invalid player object"""
        with pytest.raises(ValueError, match="missing 'playerId'"):
            validate_lineup([{"battingOrder": 1}])
    
    def test_lineup_duplicate_batting_order(self):
        """Test lineup with duplicate batting order"""
        lineup = [
            {"playerId": "player-1", "battingOrder": 1, "position": "1B"},
            {"playerId": "player-2", "battingOrder": 1, "position": "SS"}
        ]
        with pytest.raises(ValueError, match="Duplicate batting order"):
            validate_lineup(lineup)
    
    def test_lineup_invalid_batting_order(self):
        """Test lineup with invalid batting order"""
        lineup = [
            {"playerId": "player-1", "battingOrder": 0, "position": "1B"}
        ]
        with pytest.raises(ValueError, match="must be 1 or greater"):
            validate_lineup(lineup)
    
    def test_lineup_with_optional_fields(self):
        """Test lineup with optional fields"""
        lineup = [
            {"playerId": "player-1", "battingOrder": 1, "position": "1B"}
        ]
        result = validate_lineup(lineup)
        assert result[0]["playerId"] == "player-1"
        assert result[0]["battingOrder"] == 1

