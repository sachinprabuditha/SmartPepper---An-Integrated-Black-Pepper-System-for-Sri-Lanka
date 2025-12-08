using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKR_Backend_API.DTOs;
using SKR_Backend_API.Models;
using SKR_Backend_API.Services;
using System.Security.Claims;

namespace SKR_Backend_API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PlantationController : ControllerBase
{
    private readonly IPlantationService _plantationService;
    private readonly ILogger<PlantationController> _logger;

    public PlantationController(IPlantationService plantationService, ILogger<PlantationController> logger)
    {
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
    /// Start a new plantation (Part 02 - Planting Start)
    /// </summary>
    [HttpPost("start")]
    [ProducesResponseType(typeof(ApiResponse<FarmRecord>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ApiResponse<FarmRecord>>> StartPlantation([FromBody] CreateFarmRecordDto createDto)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
            return BadRequest(ApiResponse<object>.ErrorResponse($"Validation failed: {string.Join(", ", errors)}"));
        }

        try
        {
            var userId = GetUserId();
            var farmRecord = await _plantationService.StartPlantationAsync(userId, createDto);
            return CreatedAtAction(nameof(GetFarmById), new { farmId = farmRecord.Id.ToString() },
                ApiResponse<FarmRecord>.SuccessResponse(farmRecord, "Plantation started successfully. Schedule generated."));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error starting plantation: {Message}", ex.Message);
            _logger.LogError(ex, "Stack trace: {StackTrace}", ex.StackTrace);
            if (ex.InnerException != null)
            {
                _logger.LogError(ex.InnerException, "Inner exception: {Message}", ex.InnerException.Message);
                _logger.LogError(ex.InnerException, "Inner stack trace: {StackTrace}", ex.InnerException.StackTrace);
            }
            var errorMessage = $"An error occurred while starting the plantation: {ex.Message}";
            if (ex.InnerException != null)
            {
                errorMessage += $" Inner: {ex.InnerException.Message}";
            }
            return StatusCode(500, ApiResponse<object>.ErrorResponse(errorMessage));
        }
    }

    /// <summary>
    /// Get all farms for the authenticated user
    /// </summary>
    [HttpGet("farms")]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<FarmRecord>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<IEnumerable<FarmRecord>>>> GetFarms()
    {
        try
        {
            var userId = GetUserId();
            var farms = await _plantationService.GetFarmsByUserIdAsync(userId);
            return Ok(ApiResponse<IEnumerable<FarmRecord>>.SuccessResponse(farms, "Farms retrieved successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving farms: {Message}", ex.Message);
            _logger.LogError(ex, "Stack trace: {StackTrace}", ex.StackTrace);
            if (ex.InnerException != null)
            {
                _logger.LogError(ex.InnerException, "Inner exception: {Message}", ex.InnerException.Message);
            }
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"An error occurred while retrieving farms: {ex.Message}"));
        }
    }

    /// <summary>
    /// Get a farm by ID
    /// </summary>
    [HttpGet("farm/{farmId}")]
    [ProducesResponseType(typeof(ApiResponse<FarmRecord>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<FarmRecord>>> GetFarmById(string farmId)
    {
        try
        {
            var farm = await _plantationService.GetFarmByIdAsync(farmId);
            if (farm == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Farm not found"));
            }

            // Verify ownership
            var userId = GetUserId();
            // Convert string userId to Guid for comparison
            if (!Guid.TryParse(userId, out var guidUserId) || farm.UserId != guidUserId)
            {
                return Forbid();
            }

            return Ok(ApiResponse<FarmRecord>.SuccessResponse(farm, "Farm retrieved successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving farm {FarmId}", farmId);
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while retrieving the farm"));
        }
    }

    /// <summary>
    /// Update a farm record
    /// </summary>
    [HttpPut("farm/{farmId}")]
    [ProducesResponseType(typeof(ApiResponse<FarmRecord>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<FarmRecord>>> UpdateFarm(string farmId, [FromBody] UpdateFarmRecordDto updateDto)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
            return BadRequest(ApiResponse<object>.ErrorResponse($"Validation failed: {string.Join(", ", errors)}"));
        }

        try
        {
            var existingFarm = await _plantationService.GetFarmByIdAsync(farmId);
            if (existingFarm == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Farm not found"));
            }

            // Verify ownership
            var userId = GetUserId();
            // Convert string userId to Guid for comparison
            if (!Guid.TryParse(userId, out var guidUserId) || existingFarm.UserId != guidUserId)
            {
                return Forbid();
            }

            var farm = await _plantationService.UpdateFarmAsync(farmId, updateDto);
            return Ok(ApiResponse<FarmRecord>.SuccessResponse(farm, "Farm updated successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating farm {FarmId}", farmId);
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while updating the farm"));
        }
    }

    /// <summary>
    /// Delete a farm record
    /// </summary>
    [HttpDelete("farm/{farmId}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<object>>> DeleteFarm(string farmId)
    {
        try
        {
            var existingFarm = await _plantationService.GetFarmByIdAsync(farmId);
            if (existingFarm == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Farm not found"));
            }

            // Verify ownership
            var userId = GetUserId();
            // Convert string userId to Guid for comparison
            if (!Guid.TryParse(userId, out var guidUserId) || existingFarm.UserId != guidUserId)
            {
                return Forbid();
            }

            var deleted = await _plantationService.DeleteFarmAsync(farmId);
            if (!deleted)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Farm not found"));
            }

            return Ok(ApiResponse<object>.SuccessResponse("Farm deleted successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting farm {FarmId}: {Message}", farmId, ex.Message);
            if (ex.InnerException != null)
            {
                _logger.LogError(ex.InnerException, "Inner exception: {Message}", ex.InnerException.Message);
            }
            var errorMessage = ex.InnerException != null 
                ? $"An error occurred while deleting the farm: {ex.InnerException.Message}"
                : $"An error occurred while deleting the farm: {ex.Message}";
            return StatusCode(500, ApiResponse<object>.ErrorResponse(errorMessage));
        }
    }

    /// <summary>
    /// Get all tasks for a specific farm (Part 03 - Display Timeline)
    /// </summary>
    [HttpGet("tasks/{farmId}")]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<FarmTask>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<IEnumerable<FarmTask>>>> GetTasksByFarmId(string farmId)
    {
        try
        {
            var existingFarm = await _plantationService.GetFarmByIdAsync(farmId);
            if (existingFarm == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Farm not found"));
            }

            // Verify ownership
            var userId = GetUserId();
            // Convert string userId to Guid for comparison
            if (!Guid.TryParse(userId, out var guidUserId) || existingFarm.UserId != guidUserId)
            {
                return Forbid();
            }

            var tasks = await _plantationService.GetTasksByFarmIdAsync(farmId);
            return Ok(ApiResponse<IEnumerable<FarmTask>>.SuccessResponse(tasks, "Tasks retrieved successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving tasks for farm {FarmId}", farmId);
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while retrieving tasks"));
        }
    }

    /// <summary>
    /// Complete a task with input details (Part 04.2/04.3 - Record Keeping)
    /// </summary>
    [HttpPut("task/complete/{taskId}")]
    [ProducesResponseType(typeof(ApiResponse<FarmTask>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<FarmTask>>> CompleteTask(string taskId, [FromBody] CompleteTaskDto completeDto)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
            return BadRequest(ApiResponse<object>.ErrorResponse($"Validation failed: {string.Join(", ", errors)}"));
        }

        try
        {
            var task = await _plantationService.CompleteTaskAsync(taskId, completeDto);
            if (task == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Task not found"));
            }

            return Ok(ApiResponse<FarmTask>.SuccessResponse(task, "Task completed successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error completing task {TaskId}", taskId);
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while completing the task"));
        }
    }

    /// <summary>
    /// Create a manual task (emergency or custom task)
    /// </summary>
    [HttpPost("tasks/manual")]
    [ProducesResponseType(typeof(ApiResponse<FarmTask>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ApiResponse<FarmTask>>> CreateManualTask([FromBody] CreateManualTaskDto createDto)
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

            var task = await _plantationService.CreateManualTaskAsync(createDto.FarmId, createDto);
            return CreatedAtAction(
                nameof(GetTasksByFarmId),
                new { farmId = createDto.FarmId },
                ApiResponse<FarmTask>.SuccessResponse(task, "Manual task created successfully")
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating manual task");
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while creating the manual task"));
        }
    }

    /// <summary>
    /// Update task details (manual tasks only, before completion)
    /// </summary>
    [HttpPut("tasks/{taskId}")]
    [ProducesResponseType(typeof(ApiResponse<FarmTask>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<FarmTask>>> UpdateTaskDetails(string taskId, [FromBody] UpdateTaskDto updateDto)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
            return BadRequest(ApiResponse<object>.ErrorResponse($"Validation failed: {string.Join(", ", errors)}"));
        }

        try
        {
            var userId = GetUserId();
            
            // Get task to verify ownership
            var task = await _plantationService.GetTaskByIdAsync(taskId);
            if (task == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Task not found"));
            }

            // Verify farm ownership
            // Convert string userId to Guid for comparison
            if (!Guid.TryParse(userId, out var guidUserId))
            {
                return Forbid();
            }
            
            var farm = await _plantationService.GetFarmByIdAsync(task.FarmId.ToString());
            if (farm == null || farm.UserId != guidUserId)
            {
                return Forbid();
            }

            var updatedTask = await _plantationService.UpdateTaskDetailsAsync(taskId, updateDto);
            if (updatedTask == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Task not found"));
            }

            return Ok(ApiResponse<FarmTask>.SuccessResponse(updatedTask, "Task updated successfully"));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating task {TaskId}", taskId);
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while updating the task"));
        }
    }

    /// <summary>
    /// Update completion details (both manual and auto tasks, after completion)
    /// </summary>
    [HttpPut("tasks/{taskId}/completion")]
    [ProducesResponseType(typeof(ApiResponse<FarmTask>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<FarmTask>>> UpdateCompletionDetails(string taskId, [FromBody] UpdateCompletionDetailsDto updateDto)
    {
        // Log the incoming request for debugging
        _logger.LogInformation("UpdateCompletionDetails called for task {TaskId}. Items count: {Count}, LaborHours: {Hours}, Notes: {Notes}", 
            taskId, updateDto.Items?.Count ?? 0, updateDto.LaborHours, updateDto.Notes ?? "null");
        
        if (updateDto.Items != null && updateDto.Items.Count > 0)
        {
            foreach (var item in updateDto.Items)
            {
                _logger.LogInformation("Item: Name={Name}, Quantity={Qty}, Cost={Cost}, Unit={Unit}", 
                    item.ItemName, item.Quantity, item.UnitCostLKR, item.Unit);
            }
        }

        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
            _logger.LogWarning("Validation failed: {Errors}", string.Join(", ", errors));
            return BadRequest(ApiResponse<object>.ErrorResponse($"Validation failed: {string.Join(", ", errors)}"));
        }

        try
        {
            var userId = GetUserId();
            
            // Get task to verify ownership
            var task = await _plantationService.GetTaskByIdAsync(taskId);
            if (task == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Task not found"));
            }

            // Verify farm ownership
            // Convert string userId to Guid for comparison
            if (!Guid.TryParse(userId, out var guidUserId))
            {
                return Forbid();
            }
            
            var farm = await _plantationService.GetFarmByIdAsync(task.FarmId.ToString());
            if (farm == null || farm.UserId != guidUserId)
            {
                return Forbid();
            }

            var updatedTask = await _plantationService.UpdateCompletionDetailsAsync(taskId, updateDto);
            if (updatedTask == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Task not found"));
            }

            _logger.LogInformation("UpdateCompletionDetails successful. Updated items count: {Count}", 
                updatedTask.InputDetails?.Items?.Count ?? 0);

            return Ok(ApiResponse<FarmTask>.SuccessResponse(updatedTask, "Completion details updated successfully"));
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogError(ex, "Invalid operation in UpdateCompletionDetails");
            return BadRequest(ApiResponse<object>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating completion details for task {TaskId}", taskId);
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while updating completion details"));
        }
    }

    /// <summary>
    /// Delete a task (manual tasks only, before completion)
    /// </summary>
    [HttpDelete("tasks/{taskId}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<object>>> DeleteTask(string taskId)
    {
        try
        {
            var userId = GetUserId();
            
            // Get task to verify ownership
            var task = await _plantationService.GetTaskByIdAsync(taskId);
            if (task == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Task not found"));
            }

            // Verify farm ownership
            // Convert string userId to Guid for comparison
            if (!Guid.TryParse(userId, out var guidUserId))
            {
                return Forbid();
            }
            
            var farm = await _plantationService.GetFarmByIdAsync(task.FarmId.ToString());
            if (farm == null || farm.UserId != guidUserId)
            {
                return Forbid();
            }

            var deleted = await _plantationService.DeleteTaskAsync(taskId);
            if (!deleted)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Task not found"));
            }

            return Ok(ApiResponse<object>.SuccessResponse(null, "Task deleted successfully"));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting task {TaskId}", taskId);
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while deleting the task"));
        }
    }
}

