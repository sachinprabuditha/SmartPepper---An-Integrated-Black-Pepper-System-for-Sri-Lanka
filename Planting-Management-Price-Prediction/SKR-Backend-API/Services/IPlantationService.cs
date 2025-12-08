using SKR_Backend_API.DTOs;
using SKR_Backend_API.Models;

namespace SKR_Backend_API.Services;

public interface IPlantationService
{
    Task<FarmRecord> StartPlantationAsync(string userId, CreateFarmRecordDto createDto);
    Task<IEnumerable<FarmRecord>> GetFarmsByUserIdAsync(string userId);
    Task<FarmRecord?> GetFarmByIdAsync(string farmId);
    Task<FarmRecord?> UpdateFarmAsync(string farmId, UpdateFarmRecordDto updateDto);
    Task<bool> DeleteFarmAsync(string farmId);
    Task<IEnumerable<FarmTask>> GetTasksByFarmIdAsync(string farmId);
    Task<FarmTask?> GetTaskByIdAsync(string taskId);
    Task<FarmTask?> CompleteTaskAsync(string taskId, CompleteTaskDto completeDto);
    Task<FarmTask> CreateManualTaskAsync(string farmId, CreateManualTaskDto createDto);
    Task<FarmTask?> UpdateTaskDetailsAsync(string taskId, UpdateTaskDto updateDto);
    Task<FarmTask?> UpdateCompletionDetailsAsync(string taskId, UpdateCompletionDetailsDto updateDto);
    Task<bool> DeleteTaskAsync(string taskId);
    Task GenerateScheduleForFarmAsync(FarmRecord farmRecord);
}

