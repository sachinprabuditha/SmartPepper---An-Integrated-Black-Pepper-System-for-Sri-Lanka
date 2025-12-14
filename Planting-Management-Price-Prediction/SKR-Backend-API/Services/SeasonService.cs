using SKR_Backend_API.DTOs;
using SKR_Backend_API.Models;
using SKR_Backend_API.Repositories;

namespace SKR_Backend_API.Services;

public class SeasonService : ISeasonService
{
    private readonly ISeasonRepository _seasonRepository;

    public SeasonService(ISeasonRepository seasonRepository)
    {
        _seasonRepository = seasonRepository;
    }

    public async Task<Season> CreateSeasonAsync(CreateSeasonDto createDto)
    {
        // Convert string IDs to Guid
        if (!Guid.TryParse(createDto.FarmId, out var guidFarmId))
        {
            throw new ArgumentException("Invalid farm ID format", nameof(createDto.FarmId));
        }

        if (!Guid.TryParse(createDto.CreatedBy, out var guidCreatedBy))
        {
            throw new ArgumentException("Invalid user ID format", nameof(createDto.CreatedBy));
        }

        var season = new Season
        {
            SeasonName = createDto.SeasonName,
            StartMonth = createDto.StartMonth,
            StartYear = createDto.StartYear,
            EndMonth = createDto.EndMonth,
            EndYear = createDto.EndYear,
            FarmId = guidFarmId,
            CreatedBy = guidCreatedBy
        };

        return await _seasonRepository.CreateAsync(season);
    }

    public async Task<IEnumerable<Season>> GetSeasonsByUserIdAsync(string userId)
    {
        return await _seasonRepository.GetByUserIdAsync(userId);
    }

    public async Task<IEnumerable<Season>> GetSeasonsByFarmIdAsync(string farmId)
    {
        return await _seasonRepository.GetByFarmIdAsync(farmId);
    }

    public async Task<Season?> GetSeasonByIdAsync(string seasonId)
    {
        return await _seasonRepository.GetByIdAsync(seasonId);
    }

    public async Task<Season?> UpdateSeasonAsync(string seasonId, UpdateSeasonDto updateDto)
    {
        var existingSeason = await _seasonRepository.GetByIdAsync(seasonId);
        if (existingSeason == null)
            return null;

        if (!string.IsNullOrWhiteSpace(updateDto.SeasonName))
            existingSeason.SeasonName = updateDto.SeasonName;

        if (updateDto.StartMonth.HasValue)
            existingSeason.StartMonth = updateDto.StartMonth.Value;

        if (updateDto.StartYear.HasValue)
            existingSeason.StartYear = updateDto.StartYear.Value;

        if (updateDto.EndMonth.HasValue)
            existingSeason.EndMonth = updateDto.EndMonth.Value;

        if (updateDto.EndYear.HasValue)
            existingSeason.EndYear = updateDto.EndYear.Value;

        if (!string.IsNullOrWhiteSpace(updateDto.FarmId))
        {
            if (!Guid.TryParse(updateDto.FarmId, out var guidFarmId))
            {
                throw new ArgumentException("Invalid farm ID format", nameof(updateDto.FarmId));
            }
            existingSeason.FarmId = guidFarmId;
        }

        return await _seasonRepository.UpdateAsync(seasonId, existingSeason);
    }

    public async Task<bool> EndSeasonAsync(string seasonId)
    {
        var existingSeason = await _seasonRepository.GetByIdAsync(seasonId);
        if (existingSeason == null)
            return false;

        existingSeason.Status = "season-end";
        var updated = await _seasonRepository.UpdateAsync(seasonId, existingSeason);
        return updated != null;
    }

    public async Task<bool> DeleteSeasonAsync(string seasonId)
    {
        return await _seasonRepository.DeleteAsync(seasonId);
    }
}

