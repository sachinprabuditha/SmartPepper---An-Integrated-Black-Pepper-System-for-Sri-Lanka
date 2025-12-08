using SKR_Backend_API.Models;

namespace SKR_Backend_API.Repositories;

public interface IFarmTaskRepository
{
    Task<FarmTask> CreateAsync(FarmTask task);
    Task<IEnumerable<FarmTask>> GetByFarmIdAsync(Guid farmId);
    Task<FarmTask?> GetByIdAsync(Guid taskId);
    Task<FarmTask?> UpdateAsync(Guid taskId, FarmTask task);
    Task<bool> DeleteAsync(Guid taskId);
    Task<bool> DeleteByFarmIdAsync(Guid farmId);
}

