using SKR_Backend_API.DTOs;
using SKR_Backend_API.Models;

namespace SKR_Backend_API.Services;

public interface ISeasonService
{
    Task<Season> CreateSeasonAsync(CreateSeasonDto createDto);
    Task<IEnumerable<Season>> GetSeasonsByUserIdAsync(string userId);
    Task<IEnumerable<Season>> GetSeasonsByFarmIdAsync(string farmId);
    Task<Season?> GetSeasonByIdAsync(string seasonId);
    Task<Season?> UpdateSeasonAsync(string seasonId, UpdateSeasonDto updateDto);
    Task<bool> EndSeasonAsync(string seasonId);
    Task<bool> DeleteSeasonAsync(string seasonId);
}

