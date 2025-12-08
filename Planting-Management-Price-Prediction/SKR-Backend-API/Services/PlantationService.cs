using Microsoft.EntityFrameworkCore;
using SKR_Backend_API.Data;
using SKR_Backend_API.DTOs;
using SKR_Backend_API.Models;
using SKR_Backend_API.Repositories;

namespace SKR_Backend_API.Services;

public class PlantationService : IPlantationService
{
    private readonly IFarmRecordRepository _farmRecordRepository;
    private readonly IAgronomyTemplateRepository _templateRepository;
    private readonly IFarmTaskRepository _taskRepository;
    private readonly IVarietyRepository _varietyRepository;
    private readonly AppDbContext _context;
    private readonly ILogger<PlantationService> _logger;

    public PlantationService(
        IFarmRecordRepository farmRecordRepository,
        IAgronomyTemplateRepository templateRepository,
        IFarmTaskRepository taskRepository,
        IVarietyRepository varietyRepository,
        AppDbContext context,
        ILogger<PlantationService> logger)
    {
        _farmRecordRepository = farmRecordRepository;
        _templateRepository = templateRepository;
        _taskRepository = taskRepository;
        _varietyRepository = varietyRepository;
        _context = context;
        _logger = logger;
    }

    public async Task<FarmRecord> StartPlantationAsync(string userId, CreateFarmRecordDto createDto)
    {
        // Convert string userId to Guid
        if (!Guid.TryParse(userId, out var guidUserId))
        {
            throw new ArgumentException("Invalid user ID format", nameof(userId));
        }

        // Validate foreign key references exist
        var districtExists = await _context.Districts.AnyAsync(d => d.Id == createDto.DistrictId);
        if (!districtExists)
        {
            throw new ArgumentException($"District with ID {createDto.DistrictId} does not exist", nameof(createDto.DistrictId));
        }

        var soilTypeExists = await _context.SoilTypes.AnyAsync(s => s.Id == createDto.SoilTypeId);
        if (!soilTypeExists)
        {
            throw new ArgumentException($"Soil type with ID {createDto.SoilTypeId} does not exist", nameof(createDto.SoilTypeId));
        }

        var varietyExists = await _context.PepperVarieties.AnyAsync(v => v.Id == createDto.ChosenVarietyId);
        if (!varietyExists)
        {
            throw new ArgumentException($"Variety with ID {createDto.ChosenVarietyId} does not exist", nameof(createDto.ChosenVarietyId));
        }

        // Normalize farm start date to midnight UTC to preserve the selected date regardless of timezone
        // CRITICAL: Extract date components from the ORIGINAL date BEFORE converting to UTC
        // This ensures December 24 stays December 24, not December 23
        var incomingDate = createDto.FarmStartDate;
        
        // Extract year, month, day from the original date (preserves the selected day)
        // Then create a new UTC DateTime at midnight with those components
        var normalizedFarmStartDate = new DateTime(
            incomingDate.Year,
            incomingDate.Month,
            incomingDate.Day,
            0, 0, 0,
            DateTimeKind.Utc
        );

        var farmRecord = new FarmRecord
        {
            UserId = guidUserId,
            FarmName = createDto.FarmName,
            DistrictId = createDto.DistrictId,
            SoilTypeId = createDto.SoilTypeId,
            ChosenVarietyId = createDto.ChosenVarietyId,
            FarmStartDate = normalizedFarmStartDate,
            AreaHectares = (decimal?)createDto.AreaHectares,
            TotalVines = createDto.TotalVines,
            CreatedAt = DateTime.UtcNow
        };

        try
        {
            var createdFarm = await _farmRecordRepository.CreateAsync(farmRecord);

            // CRITICAL: Generate schedule after creating farm record
            // Wrap in try-catch so farm creation succeeds even if schedule generation fails
            try
            {
                _logger.LogInformation($"Starting schedule generation for farm {createdFarm.Id}");
                await GenerateScheduleForFarmAsync(createdFarm);
                _logger.LogInformation($"Successfully generated schedule for farm {createdFarm.Id}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to generate schedule for farm {createdFarm.Id}, but farm was created successfully. Error: {ex.Message}");
                if (ex.InnerException != null)
                {
                    _logger.LogError(ex.InnerException, $"Inner exception: {ex.InnerException.Message}");
                }
                // Don't throw - farm is created, schedule can be regenerated later if needed
            }

            return createdFarm;
        }
        catch (DbUpdateException dbEx)
        {
            _logger.LogError(dbEx, "Database error creating farm: {Message}", dbEx.Message);
            if (dbEx.InnerException != null)
            {
                _logger.LogError(dbEx.InnerException, "Inner database exception: {Message}", dbEx.InnerException.Message);
            }
            throw new Exception($"Database error: {dbEx.Message}. Inner: {dbEx.InnerException?.Message}", dbEx);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating farm: {Message}", ex.Message);
            throw;
        }
    }

    public async Task<IEnumerable<FarmRecord>> GetFarmsByUserIdAsync(string userId)
    {
        return await _farmRecordRepository.GetByUserIdAsync(userId);
    }

    public async Task<FarmRecord?> GetFarmByIdAsync(string farmId)
    {
        return await _farmRecordRepository.GetByIdAsync(farmId);
    }

    public async Task<FarmRecord?> UpdateFarmAsync(string farmId, UpdateFarmRecordDto updateDto)
    {
        if (!Guid.TryParse(farmId, out var guidFarmId))
        {
            throw new ArgumentException("Invalid farm ID format", nameof(farmId));
        }

        // Get existing farm - need tracking for updates
        var existingFarm = await _context.Farms
            .FirstOrDefaultAsync(f => f.Id == guidFarmId);

        if (existingFarm == null)
            return null;

        // Validate foreign key references if they're being updated
        if (updateDto.DistrictId.HasValue)
        {
            var districtExists = await _context.Districts.AnyAsync(d => d.Id == updateDto.DistrictId.Value);
            if (!districtExists)
            {
                throw new ArgumentException($"District with ID {updateDto.DistrictId.Value} does not exist", nameof(updateDto.DistrictId));
            }
            existingFarm.DistrictId = updateDto.DistrictId.Value;
        }

        if (updateDto.SoilTypeId.HasValue)
        {
            var soilTypeExists = await _context.SoilTypes.AnyAsync(s => s.Id == updateDto.SoilTypeId.Value);
            if (!soilTypeExists)
            {
                throw new ArgumentException($"Soil type with ID {updateDto.SoilTypeId.Value} does not exist", nameof(updateDto.SoilTypeId));
            }
            existingFarm.SoilTypeId = updateDto.SoilTypeId.Value;
        }

        if (!string.IsNullOrEmpty(updateDto.ChosenVarietyId))
        {
            var varietyExists = await _context.PepperVarieties.AnyAsync(v => v.Id == updateDto.ChosenVarietyId);
            if (!varietyExists)
            {
                throw new ArgumentException($"Variety with ID {updateDto.ChosenVarietyId} does not exist", nameof(updateDto.ChosenVarietyId));
            }
            existingFarm.ChosenVarietyId = updateDto.ChosenVarietyId;
        }

        // Update other properties
        if (!string.IsNullOrEmpty(updateDto.FarmName))
            existingFarm.FarmName = updateDto.FarmName;
        
        if (updateDto.FarmStartDate.HasValue)
        {
            // Normalize farm start date to midnight UTC to preserve the selected date regardless of timezone
            // CRITICAL: Extract date components from the ORIGINAL date BEFORE converting to UTC
            var incomingDate = updateDto.FarmStartDate.Value;
            
            existingFarm.FarmStartDate = new DateTime(
                incomingDate.Year,
                incomingDate.Month,
                incomingDate.Day,
                0, 0, 0,
                DateTimeKind.Utc
            );
        }
        
        if (updateDto.AreaHectares.HasValue)
            existingFarm.AreaHectares = (decimal?)updateDto.AreaHectares.Value;
        
        if (updateDto.TotalVines.HasValue)
            existingFarm.TotalVines = updateDto.TotalVines.Value;

        await _context.SaveChangesAsync();

        // Reload related data to populate District and ChosenVariety
        if (existingFarm.DistrictId.HasValue)
        {
            var district = await _context.Districts.FirstOrDefaultAsync(d => d.Id == existingFarm.DistrictId.Value);
            existingFarm.District = district?.Name ?? string.Empty;
        }
        else
        {
            existingFarm.District = string.Empty;
        }

        if (!string.IsNullOrEmpty(existingFarm.ChosenVarietyId))
        {
            var variety = await _context.PepperVarieties.FirstOrDefaultAsync(v => v.Id == existingFarm.ChosenVarietyId);
            existingFarm.ChosenVariety = variety?.Name ?? string.Empty;
        }
        else
        {
            existingFarm.ChosenVariety = string.Empty;
        }

        return existingFarm;
    }

    public async Task<bool> DeleteFarmAsync(string farmId)
    {
        if (!Guid.TryParse(farmId, out var farmIdGuid))
        {
            throw new ArgumentException("Invalid farm ID format", nameof(farmId));
        }

        try
        {
            // Delete all associated tasks first
            await _taskRepository.DeleteByFarmIdAsync(farmIdGuid);
            
            // Then delete the farm
            return await _farmRecordRepository.DeleteAsync(farmId);
        }
        catch (Microsoft.EntityFrameworkCore.DbUpdateException dbEx)
        {
            _logger.LogError(dbEx, "Database error deleting farm {FarmId}: {Message}", farmId, dbEx.Message);
            if (dbEx.InnerException != null)
            {
                _logger.LogError(dbEx.InnerException, "Inner database exception: {Message}", dbEx.InnerException.Message);
            }
            throw new Exception($"Database error deleting farm: {dbEx.Message}. Inner: {dbEx.InnerException?.Message}", dbEx);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting farm {FarmId}: {Message}", farmId, ex.Message);
            throw;
        }
    }

    public async Task<IEnumerable<FarmTask>> GetTasksByFarmIdAsync(string farmId)
    {
        if (!Guid.TryParse(farmId, out var farmIdGuid))
        {
            throw new ArgumentException("Invalid farm ID format", nameof(farmId));
        }

        var tasks = await _taskRepository.GetByFarmIdAsync(farmIdGuid);
        
        // Update overdue tasks
        var now = DateTime.UtcNow;
        foreach (var task in tasks.Where(t => t.Status == "Scheduled" && t.DueDate < now))
        {
            task.Status = "Overdue";
            await _taskRepository.UpdateAsync(task.Id, task);
        }

        return await _taskRepository.GetByFarmIdAsync(farmIdGuid);
    }

    public async Task<FarmTask?> GetTaskByIdAsync(string taskId)
    {
        if (!Guid.TryParse(taskId, out var taskIdGuid))
        {
            return null;
        }
        
        var task = await _taskRepository.GetByIdAsync(taskIdGuid);
        
        // Update overdue status if needed
        if (task != null && task.Status == "Scheduled" && task.DueDate < DateTime.UtcNow)
        {
            task.Status = "Overdue";
            await _taskRepository.UpdateAsync(task.Id, task);
        }
        
        return task;
    }

    public async Task<FarmTask?> CompleteTaskAsync(string taskId, CompleteTaskDto completeDto)
    {
        if (!Guid.TryParse(taskId, out var taskIdGuid))
        {
            throw new ArgumentException("Invalid task ID format", nameof(taskId));
        }

        var task = await _taskRepository.GetByIdAsync(taskIdGuid);
        if (task == null)
            return null;

        task.Status = "Completed";
        task.DateCompleted = DateTime.UtcNow;
        task.InputDetails = new InputDetails
        {
            Items = (completeDto.Items != null && completeDto.Items.Count > 0)
                ? completeDto.Items.Select(item => new InputItem
                {
                    ItemName = item.ItemName,
                    Quantity = item.Quantity,
                    UnitCostLKR = item.UnitCostLKR,
                    Unit = item.Unit
                }).ToList()
                : new List<InputItem>(), // Empty list if no items provided
            LaborHours = completeDto.LaborHours,
            Notes = completeDto.Notes
        };

        return await _taskRepository.UpdateAsync(taskIdGuid, task);
    }

    public async Task<FarmTask> CreateManualTaskAsync(string farmId, CreateManualTaskDto createDto)
    {
        // Convert farmId string to Guid for FarmTask
        if (!Guid.TryParse(farmId, out var farmIdGuid))
        {
            throw new ArgumentException("Invalid farm ID format", nameof(farmId));
        }

        // Verify farm exists and belongs to user (repository accepts string)
        var farm = await _farmRecordRepository.GetByIdAsync(farmId);
        if (farm == null)
        {
            throw new ArgumentException("Farm not found");
        }

        var task = new FarmTask
        {
            FarmId = farmIdGuid,
            TaskName = createDto.TaskName,
            Phase = createDto.Phase ?? "Maintenance",
            TaskType = createDto.TaskType,
            VarietyKey = "ALL", // Manual tasks are not variety-specific
            DueDate = createDto.DueDate.ToUniversalTime(),
            Status = "Scheduled",
            DetailedSteps = createDto.DetailedSteps ?? new List<string>(),
            ReasonWhy = createDto.ReasonWhy ?? string.Empty,
            IsManual = true, // Mark as manual task
            Priority = createDto.Priority,
            CreatedAt = DateTime.UtcNow
        };

        return await _taskRepository.CreateAsync(task);
    }

    public async Task<FarmTask?> UpdateTaskDetailsAsync(string taskId, UpdateTaskDto updateDto)
    {
        if (!Guid.TryParse(taskId, out var taskIdGuid))
        {
            throw new ArgumentException("Invalid task ID format", nameof(taskId));
        }

        var task = await _taskRepository.GetByIdAsync(taskIdGuid);
        if (task == null)
            return null;

        // Only manual tasks can be updated before completion
        if (!task.IsManual)
        {
            throw new InvalidOperationException("Only manual tasks can be updated before completion");
        }

        // Cannot update task details after completion
        if (task.Status == "Completed")
        {
            throw new InvalidOperationException("Cannot update task details after completion. Use update completion details instead.");
        }

        task.TaskName = updateDto.TaskName;
        task.Phase = updateDto.Phase ?? task.Phase;
        task.Priority = updateDto.Priority;
        task.DueDate = updateDto.DueDate.ToUniversalTime();
        task.DetailedSteps = updateDto.DetailedSteps ?? task.DetailedSteps;
        task.ReasonWhy = updateDto.ReasonWhy ?? task.ReasonWhy;

        return await _taskRepository.UpdateAsync(taskIdGuid, task);
    }

    public async Task<FarmTask?> UpdateCompletionDetailsAsync(string taskId, UpdateCompletionDetailsDto updateDto)
    {
        if (!Guid.TryParse(taskId, out var taskIdGuid))
        {
            throw new ArgumentException("Invalid task ID format", nameof(taskId));
        }

        var task = await _taskRepository.GetByIdAsync(taskIdGuid);
        if (task == null)
            return null;

        // Can only update completion details if task is already completed
        if (task.Status != "Completed")
        {
            throw new InvalidOperationException("Task must be completed before updating completion details");
        }

        // Get current InputDetails or create new one
        var currentInputDetails = task.InputDetails ?? new InputDetails
        {
            Items = new List<InputItem>(),
            LaborHours = 0,
            Notes = null
        };

        // Always update items - if Items is provided (even if empty array), use it. Otherwise keep existing.
        // The frontend always sends items array (can be empty), so this will always update
        List<InputItem> updatedItems;
        if (updateDto.Items != null)
        {
            // Items list was provided - update with it (even if empty array to clear items)
            _logger.LogInformation("Updating completion details - Items count: {Count}", updateDto.Items.Count);
            
            updatedItems = updateDto.Items.Select(item => new InputItem
            {
                ItemName = item.ItemName ?? string.Empty,
                Quantity = item.Quantity,
                UnitCostLKR = item.UnitCostLKR,
                Unit = item.Unit ?? "kg"
            }).ToList();
            
            _logger.LogInformation("Updated items count: {Count}, First item name: {Name}", 
                updatedItems.Count, 
                updatedItems.FirstOrDefault()?.ItemName ?? "none");
        }
        else
        {
            // Keep existing items if not provided
            updatedItems = currentInputDetails.Items ?? new List<InputItem>();
            _logger.LogWarning("UpdateCompletionDetailsAsync: Items is null, keeping existing items");
        }

        // Create new InputDetails object with updated values
        // This triggers the setter which serializes to JSON
        task.InputDetails = new InputDetails
        {
            Items = updatedItems,
            LaborHours = updateDto.LaborHours,
            Notes = updateDto.Notes
        };
        
        _logger.LogInformation("InputDetailsJson after update: {Json}", task.InputDetailsJson);

        return await _taskRepository.UpdateAsync(taskIdGuid, task);
    }

    public async Task<bool> DeleteTaskAsync(string taskId)
    {
        if (!Guid.TryParse(taskId, out var taskIdGuid))
        {
            throw new ArgumentException("Invalid task ID format", nameof(taskId));
        }

        var task = await _taskRepository.GetByIdAsync(taskIdGuid);
        if (task == null)
            return false;

        // Only manual tasks can be deleted
        if (!task.IsManual)
        {
            throw new InvalidOperationException("Only manual tasks can be deleted");
        }

        // Cannot delete completed tasks
        if (task.Status == "Completed")
        {
            throw new InvalidOperationException("Cannot delete completed tasks");
        }

        return await _taskRepository.DeleteAsync(taskIdGuid);
    }

    public async Task GenerateScheduleForFarmAsync(FarmRecord farmRecord)
    {
        try
        {
            _logger.LogInformation($"Starting schedule generation for farm {farmRecord.Id}, variety ID: {farmRecord.ChosenVarietyId}");
            
            // Use variety ID directly for template matching
            string varietyKeyForQuery = "ALL"; // Default to ALL if variety not found
            if (!string.IsNullOrEmpty(farmRecord.ChosenVarietyId))
            {
                varietyKeyForQuery = farmRecord.ChosenVarietyId;
                _logger.LogInformation($"Using variety ID: {varietyKeyForQuery}");
            }

            // Get relevant templates (ALL or specific variety ID)
            _logger.LogInformation($"Querying templates for variety key: {varietyKeyForQuery}");
            var templates = await _templateRepository.GetByVarietyKeyAsync(varietyKeyForQuery);
            _logger.LogInformation($"Found {templates.Count()} templates matching variety key '{varietyKeyForQuery}'");
            
            if (!templates.Any())
            {
                _logger.LogWarning($"No templates found for variety key '{varietyKeyForQuery}'. Checking if any templates exist at all...");
                var allTemplates = await _templateRepository.GetAllAsync();
                _logger.LogInformation($"Total templates in database: {allTemplates.Count()}");
                if (allTemplates.Any())
                {
                    _logger.LogInformation($"Sample template VarietyKey values: {string.Join(", ", allTemplates.Take(5).Select(t => t.VarietyKey))}");
                }
            }

            var tasks = new List<FarmTask>();
            // Handle nullable FarmStartDate
            if (!farmRecord.FarmStartDate.HasValue)
            {
                _logger.LogWarning($"Farm {farmRecord.Id} does not have a start date. Cannot generate schedule.");
                return;
            }
            
            var farmStartDate = farmRecord.FarmStartDate.Value;
            var now = DateTime.UtcNow;
            var farmIdGuid = farmRecord.Id; // FarmTask.FarmId is now Guid

            foreach (var template in templates)
            {
                try
                {
                    _logger.LogInformation($"Processing template: {template.TaskName}, Timing: {template.TimingDaysAfterStartingOfFarm} days");
                    
                    DateTime initialDueDate;
                    string taskStatus = "Scheduled";
                    
                    // Handle timing logic:
                    // - Negative: tasks before farm start (pre-planting)
                    // - Zero: immediate tasks (due today/now, marked as needing immediate attention)
                    // - Positive: tasks after farm start
                    if (template.TimingDaysAfterStartingOfFarm == 0)
                    {
                        // Immediate task - due date is the farm start date (or today if farm already started)
                        initialDueDate = farmStartDate > now ? farmStartDate : now;
                        taskStatus = "Scheduled"; // Can be marked as overdue if past due
                        _logger.LogInformation($"Immediate task '{template.TaskName}' - Due date: {initialDueDate:yyyy-MM-dd}");
                    }
                    else
                    {
                        // Calculate due date based on timing in days (supports negative for pre-planting tasks)
                        initialDueDate = farmStartDate.AddDays(template.TimingDaysAfterStartingOfFarm);
                        _logger.LogInformation($"Scheduled task '{template.TaskName}' - Due date: {initialDueDate:yyyy-MM-dd} (Farm start: {farmStartDate:yyyy-MM-dd}, Timing: {template.TimingDaysAfterStartingOfFarm} days)");
                    }

                    // Single occurrence task (recurring functionality removed in migration)
                    tasks.Add(new FarmTask
                    {
                        FarmId = farmIdGuid,
                        TaskName = template.TaskName,
                        Phase = template.Phase ?? "Maintenance",
                        TaskType = template.TaskType,
                        VarietyKey = template.VarietyKey,
                        DueDate = initialDueDate,
                        Status = taskStatus,
                        DetailedSteps = template.GetDetailedStepsList(),
                        ReasonWhy = string.Empty, // ReasonWhy removed from AgronomyTemplate
                        CreatedAt = DateTime.UtcNow
                    });
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Error processing template '{template?.TaskName ?? "Unknown"}' for farm {farmRecord.Id}: {ex.Message}");
                    // Continue with next template instead of failing completely
                }
            }

            // District intelligence: add dry-zone seasonal triggers (e.g., Summer Irrigation)
            // Load district name from ID if available
            string? districtName = null;
            if (farmRecord.DistrictId.HasValue)
            {
                var district = await _context.Districts.FirstOrDefaultAsync(d => d.Id == farmRecord.DistrictId.Value);
                districtName = district?.Name;
            }

            var dryZoneDistricts = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "Hambantota",
                "Anuradhapura",
                "Polonnaruwa",
                "Kurunegala",
                "Monaragala"
            };

            if (!string.IsNullOrEmpty(districtName) && dryZoneDistricts.Contains(districtName))
            {
                // Schedule a \"Summer Irrigation Check\" task in March, April, and May
                var firstSeasonYear = farmStartDate.Month <= 3 ? farmStartDate.Year : farmStartDate.Year + 1;
                var summerMonths = new[] { 3, 4, 5 }; // March–May

                foreach (var month in summerMonths)
                {
                    var dueDate = new DateTime(firstSeasonYear, month, 15, 0, 0, 0, DateTimeKind.Utc);

                    tasks.Add(new FarmTask
                    {
                        FarmId = farmIdGuid,
                        TaskName = "Summer Irrigation Check",
                        Phase = "Maintenance",
                        TaskType = "Irrigation",
                        VarietyKey = "ALL",
                        DueDate = dueDate,
                        Status = "Scheduled",
                        DetailedSteps = new List<string>
                        {
                            "Inspect soil moisture at 15–20cm depth.",
                            "If soil is dry and no rain in last 5 days, schedule supplementary irrigation.",
                            "Check mulch cover around vines and repair any gaps."
                        },
                        ReasonWhy = "Dry-zone districts face high evapotranspiration from March to May. Regular irrigation checks prevent vine stress and yield loss.",
                        CreatedAt = DateTime.UtcNow
                    });
                }
            }

            // Bulk insert tasks
            int createdCount = 0;
            _logger.LogInformation($"Attempting to create {tasks.Count} tasks for farm {farmRecord.Id}");
            foreach (var task in tasks)
            {
                try
                {
                    await _taskRepository.CreateAsync(task);
                    createdCount++;
                    _logger.LogInformation($"Successfully created task '{task.TaskName}' (Due: {task.DueDate:yyyy-MM-dd})");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Failed to create task '{task.TaskName}' for farm {farmRecord.Id}: {ex.Message}");
                    if (ex.InnerException != null)
                    {
                        _logger.LogError(ex.InnerException, $"Inner exception: {ex.InnerException.Message}");
                    }
                }
            }

            _logger.LogInformation($"Generated {tasks.Count} tasks, successfully created {createdCount} tasks for farm {farmRecord.Id}");
            if (createdCount < tasks.Count)
            {
                _logger.LogWarning($"Only {createdCount} out of {tasks.Count} tasks were created for farm {farmRecord.Id}");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error generating schedule for farm {farmRecord.Id}");
            throw;
        }
    }
}

