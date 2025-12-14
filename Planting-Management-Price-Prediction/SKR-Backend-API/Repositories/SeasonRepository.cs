using Microsoft.EntityFrameworkCore;
using SKR_Backend_API.Data;
using SKR_Backend_API.Models;

namespace SKR_Backend_API.Repositories;

public class SeasonRepository : ISeasonRepository
{
    private readonly AppDbContext _context;

    public SeasonRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Season> CreateAsync(Season season)
    {
        if (season.Id == Guid.Empty)
        {
            season.Id = Guid.NewGuid();
        }
        _context.HarvestSeasons.Add(season);
        await _context.SaveChangesAsync();
        return season;
    }

    public async Task<IEnumerable<Season>> GetByUserIdAsync(string userId)
    {
        if (!Guid.TryParse(userId, out var guidUserId))
        {
            return Enumerable.Empty<Season>();
        }

        try
        {
            return await _context.HarvestSeasons
                .AsNoTracking()
                .Where(s => s.CreatedBy == guidUserId)
                .OrderByDescending(s => s.StartYear)
                .ThenByDescending(s => s.StartMonth)
                .ToListAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Error in GetByUserIdAsync: {ex.Message}");
            System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");
            if (ex.InnerException != null)
            {
                System.Diagnostics.Debug.WriteLine($"Inner exception: {ex.InnerException.Message}");
            }
            throw;
        }
    }

    public async Task<IEnumerable<Season>> GetByFarmIdAsync(string farmId)
    {
        if (!Guid.TryParse(farmId, out var guidFarmId))
        {
            return Enumerable.Empty<Season>();
        }

        return await _context.HarvestSeasons
            .Where(s => s.FarmId == guidFarmId)
            .OrderByDescending(s => s.StartYear)
            .ThenByDescending(s => s.StartMonth)
            .ToListAsync();
    }

    public async Task<Season?> GetByIdAsync(string seasonId)
    {
        if (!Guid.TryParse(seasonId, out var guidSeasonId))
        {
            return null;
        }

        return await _context.HarvestSeasons
            .FirstOrDefaultAsync(s => s.Id == guidSeasonId);
    }

    public async Task<Season?> UpdateAsync(string seasonId, Season season)
    {
        if (!Guid.TryParse(seasonId, out var guidSeasonId))
        {
            return null;
        }

        var existingSeason = await _context.HarvestSeasons
            .FirstOrDefaultAsync(s => s.Id == guidSeasonId);

        if (existingSeason == null)
        {
            return null;
        }

        // Update properties
        existingSeason.SeasonName = season.SeasonName;
        existingSeason.StartMonth = season.StartMonth;
        existingSeason.StartYear = season.StartYear;
        existingSeason.EndMonth = season.EndMonth;
        existingSeason.EndYear = season.EndYear;
        existingSeason.FarmId = season.FarmId;

        await _context.SaveChangesAsync();
        return existingSeason;
    }

    public async Task<bool> DeleteAsync(string seasonId)
    {
        if (!Guid.TryParse(seasonId, out var guidSeasonId))
        {
            return false;
        }

        var season = await _context.HarvestSeasons
            .FirstOrDefaultAsync(s => s.Id == guidSeasonId);

        if (season == null)
        {
            return false;
        }

        _context.HarvestSeasons.Remove(season);
        var result = await _context.SaveChangesAsync();
        return result > 0;
    }
}

