using SKR_Backend_API.Models;

namespace SKR_Backend_API.Repositories;

public interface ISeasonRepository
{
    Task<Season> CreateAsync(Season season);
    Task<IEnumerable<Season>> GetByUserIdAsync(string userId);
    Task<IEnumerable<Season>> GetByFarmIdAsync(string farmId);
    Task<Season?> GetByIdAsync(string seasonId);
    Task<Season?> UpdateAsync(string seasonId, Season season);
    Task<bool> DeleteAsync(string seasonId);
}

