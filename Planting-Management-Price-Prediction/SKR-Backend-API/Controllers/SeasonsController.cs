using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKR_Backend_API.DTOs;
using SKR_Backend_API.Models;
using SKR_Backend_API.Services;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;

namespace SKR_Backend_API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SeasonsController : ControllerBase
{
    private readonly ISeasonService _seasonService;
    private readonly IPlantationService _plantationService;
    private readonly ILogger<SeasonsController> _logger;

    public SeasonsController(
        ISeasonService seasonService,
        IPlantationService plantationService,
        ILogger<SeasonsController> logger)
    {
        _seasonService = seasonService;
        _plantationService = plantationService;
        _logger = logger;
    }

    private string GetUserId()
    {
        return User.FindFirstValue(ClaimTypes.NameIdentifier) ?? 
               User.FindFirstValue("userId") ?? 
               throw new UnauthorizedAccessException("User ID not found in token");
    }

    /// <summary>
    /// Create a new harvesting season for a specific farm
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<Season>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<Season>>> CreateSeason([FromBody] CreateSeasonDto createDto)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
            return BadRequest(ApiResponse<object>.ErrorResponse($"Validation failed: {string.Join(", ", errors)}"));
        }

        try
        {
            var userId = GetUserId();
            
            // Verify farm exists and belongs to user
            var farm = await _plantationService.GetFarmByIdAsync(createDto.FarmId);
            if (farm == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Farm not found"));
            }
            
            // Convert string userId to Guid for comparison
            if (!Guid.TryParse(userId, out var guidUserId) || farm.UserId != guidUserId)
            {
                return Forbid();
            }

            // Set createdBy from authenticated user
            createDto.CreatedBy = userId;

            var season = await _seasonService.CreateSeasonAsync(createDto);
            return CreatedAtAction(nameof(GetSeasonById), new { seasonId = season.Id.ToString() },
                ApiResponse<Season>.SuccessResponse(season, "Season created successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating season");
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while creating the season"));
        }
    }

    /// <summary>
    /// Get all seasons for a specific user
    /// </summary>
    [HttpGet("user/{userId}")]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<Season>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<IEnumerable<Season>>>> GetSeasonsByUserId(string userId)
    {
        try
        {
            var currentUserId = GetUserId();
            // Only allow users to get their own seasons
            if (userId != currentUserId)
            {
                return Forbid();
            }

            var seasons = await _seasonService.GetSeasonsByUserIdAsync(userId);
            return Ok(ApiResponse<IEnumerable<Season>>.SuccessResponse(seasons, "Seasons retrieved successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving seasons for user {UserId}: {Message}", userId, ex.Message);
            if (ex.InnerException != null)
            {
                _logger.LogError(ex.InnerException, "Inner exception: {Message}", ex.InnerException.Message);
            }
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"An error occurred while retrieving seasons: {ex.Message}"));
        }
    }

    /// <summary>
    /// Get all seasons for a specific farm
    /// </summary>
    [HttpGet("farm/{farmId}")]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<Season>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<IEnumerable<Season>>>> GetSeasonsByFarmId(string farmId)
    {
        try
        {
            var userId = GetUserId();
            
            // Verify farm exists and belongs to user
            var farm = await _plantationService.GetFarmByIdAsync(farmId);
            if (farm == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Farm not found"));
            }
            
            // Convert string userId to Guid for comparison
            if (!Guid.TryParse(userId, out var guidUserId) || farm.UserId != guidUserId)
            {
                return Forbid();
            }

            var seasons = await _seasonService.GetSeasonsByFarmIdAsync(farmId);
            return Ok(ApiResponse<IEnumerable<Season>>.SuccessResponse(seasons, "Seasons retrieved successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving seasons for farm {FarmId}", farmId);
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while retrieving seasons"));
        }
    }

    /// <summary>
    /// Get a season by ID
    /// </summary>
    [HttpGet("{seasonId}")]
    [ProducesResponseType(typeof(ApiResponse<Season>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<Season>>> GetSeasonById(string seasonId)
    {
        try
        {
            var season = await _seasonService.GetSeasonByIdAsync(seasonId);
            if (season == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Season not found"));
            }

            return Ok(ApiResponse<Season>.SuccessResponse(season, "Season retrieved successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving season {SeasonId}", seasonId);
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while retrieving the season"));
        }
    }

    /// <summary>
    /// Update a season
    /// </summary>
    [HttpPut("{seasonId}")]
    [ProducesResponseType(typeof(ApiResponse<Season>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<Season>>> UpdateSeason(string seasonId, [FromBody] UpdateSeasonDto updateDto)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
            return BadRequest(ApiResponse<object>.ErrorResponse($"Validation failed: {string.Join(", ", errors)}"));
        }

        try
        {
            var userId = GetUserId();
            
            // Convert string userId to Guid for comparison
            if (!Guid.TryParse(userId, out var guidUserId))
            {
                return Forbid();
            }
            
            // Get existing season to verify ownership
            var existingSeason = await _seasonService.GetSeasonByIdAsync(seasonId);
            if (existingSeason == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Season not found"));
            }

            // Verify farm ownership - convert Guid FarmId to string for service call
            var farmIdString = existingSeason.FarmId.ToString();
            var farm = await _plantationService.GetFarmByIdAsync(farmIdString);
            if (farm == null || farm.UserId != guidUserId)
            {
                return Forbid();
            }

            // If farmId is being updated, verify the new farm belongs to user
            if (!string.IsNullOrWhiteSpace(updateDto.FarmId) && updateDto.FarmId != farmIdString)
            {
                var newFarm = await _plantationService.GetFarmByIdAsync(updateDto.FarmId);
                if (newFarm == null || newFarm.UserId != guidUserId)
                {
                    return BadRequest(ApiResponse<object>.ErrorResponse("New farm not found or does not belong to user"));
                }
            }

            var season = await _seasonService.UpdateSeasonAsync(seasonId, updateDto);
            if (season == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Season not found"));
            }

            return Ok(ApiResponse<Season>.SuccessResponse(season, "Season updated successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating season {SeasonId}", seasonId);
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while updating the season"));
        }
    }

    /// <summary>
    /// End a season
    /// </summary>
    [HttpPost("{seasonId}/end")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<object>>> EndSeason(string seasonId)
    {
        try
        {
            var userId = GetUserId();
            
            // Convert string userId to Guid for comparison
            if (!Guid.TryParse(userId, out var guidUserId))
            {
                return Forbid();
            }
            
            // Get existing season to verify ownership
            var existingSeason = await _seasonService.GetSeasonByIdAsync(seasonId);
            if (existingSeason == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Season not found"));
            }

            // Verify farm ownership
            var farmIdString = existingSeason.FarmId.ToString();
            var farm = await _plantationService.GetFarmByIdAsync(farmIdString);
            if (farm == null || farm.UserId != guidUserId)
            {
                return Forbid();
            }

            var success = await _seasonService.EndSeasonAsync(seasonId);
            if (!success)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Season not found"));
            }

            return Ok(ApiResponse<object>.SuccessResponse("Season ended successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error ending season {SeasonId}", seasonId);
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while ending the season"));
        }
    }

    /// <summary>
    /// Delete a season
    /// </summary>
    [HttpDelete("{seasonId}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<object>>> DeleteSeason(string seasonId)
    {
        try
        {
            var userId = GetUserId();
            
            // Convert string userId to Guid for comparison
            if (!Guid.TryParse(userId, out var guidUserId))
            {
                return Forbid();
            }
            
            // Get existing season to verify ownership
            var existingSeason = await _seasonService.GetSeasonByIdAsync(seasonId);
            if (existingSeason == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Season not found"));
            }

            // Verify farm ownership - convert Guid FarmId to string for service call
            var farmIdString = existingSeason.FarmId.ToString();
            var farm = await _plantationService.GetFarmByIdAsync(farmIdString);
            if (farm == null || farm.UserId != guidUserId)
            {
                return Forbid();
            }

            var deleted = await _seasonService.DeleteSeasonAsync(seasonId);
            if (!deleted)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Season not found"));
            }

            return Ok(ApiResponse<object>.SuccessResponse("Season deleted successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting season {SeasonId}", seasonId);
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while deleting the season"));
        }
    }
}

