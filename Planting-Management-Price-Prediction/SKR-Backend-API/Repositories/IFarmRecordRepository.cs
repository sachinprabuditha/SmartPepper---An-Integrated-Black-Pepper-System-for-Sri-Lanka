using SKR_Backend_API.Models;

namespace SKR_Backend_API.Repositories;

public interface IFarmRecordRepository
{
    Task<FarmRecord> CreateAsync(FarmRecord farmRecord);
    Task<IEnumerable<FarmRecord>> GetByUserIdAsync(string userId);
    Task<FarmRecord?> GetByIdAsync(string farmId);
    Task<FarmRecord?> UpdateAsync(string farmId, FarmRecord farmRecord);
    Task<bool> DeleteAsync(string farmId);
}

