using Microsoft.EntityFrameworkCore;
using SKR_Backend_API.Data;
using SKR_Backend_API.Models;

namespace SKR_Backend_API.Repositories;

public class FarmRecordRepository : IFarmRecordRepository
{
    private readonly AppDbContext _context;

    public FarmRecordRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<FarmRecord> CreateAsync(FarmRecord farmRecord)
    {
        // Generate new Guid if not set
        if (farmRecord.Id == Guid.Empty)
        {
            farmRecord.Id = Guid.NewGuid();
        }
        
        farmRecord.CreatedAt = DateTime.UtcNow;

        _context.Farms.Add(farmRecord);
        await _context.SaveChangesAsync();
        return farmRecord;
    }

    public async Task<IEnumerable<FarmRecord>> GetByUserIdAsync(string userId)
    {
        if (!Guid.TryParse(userId, out var guidUserId))
        {
            return Enumerable.Empty<FarmRecord>();
        }

        try
        {
            // Query farms first - use AsNoTracking to prevent EF Core from trying to access navigation properties
            var farms = await _context.Farms
                .AsNoTracking()
                .Where(f => f.UserId == guidUserId)
                .OrderByDescending(f => f.CreatedAt)
                .ToListAsync();

            // Load related data separately to avoid Include() issues
            var districtIds = farms.Where(f => f.DistrictId.HasValue).Select(f => f.DistrictId!.Value).Distinct().ToList();
            var soilTypeIds = farms.Where(f => f.SoilTypeId.HasValue).Select(f => f.SoilTypeId!.Value).Distinct().ToList();
            var varietyIds = farms.Where(f => !string.IsNullOrEmpty(f.ChosenVarietyId)).Select(f => f.ChosenVarietyId!).Distinct().ToList();

            var districts = districtIds.Any() 
                ? await _context.Districts.Where(d => districtIds.Contains(d.Id)).ToListAsync()
                : new List<District>();
            
            var soilTypes = soilTypeIds.Any()
                ? await _context.SoilTypes.Where(s => soilTypeIds.Contains(s.Id)).ToListAsync()
                : new List<SoilType>();
            
            var varieties = varietyIds.Any()
                ? await _context.PepperVarieties.Where(v => varietyIds.Contains(v.Id)).ToListAsync()
                : new List<BlackPepperVariety>();

            // Populate District and ChosenVariety from loaded data
            foreach (var farm in farms)
            {
                if (farm.DistrictId.HasValue)
                {
                    var district = districts.FirstOrDefault(d => d.Id == farm.DistrictId.Value);
                    farm.District = district?.Name ?? string.Empty;
                }
                else
                {
                    farm.District = string.Empty;
                }

                if (!string.IsNullOrEmpty(farm.ChosenVarietyId))
                {
                    var variety = varieties.FirstOrDefault(v => v.Id == farm.ChosenVarietyId);
                    farm.ChosenVariety = variety?.Name ?? string.Empty;
                }
                else
                {
                    farm.ChosenVariety = string.Empty;
                }
            }

            return farms;
        }
        catch (Exception ex)
        {
            // Log the error and return empty list if query fails
            // This prevents the entire request from failing
            System.Diagnostics.Debug.WriteLine($"Error in GetByUserIdAsync: {ex.Message}");
            System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");
            if (ex.InnerException != null)
            {
                System.Diagnostics.Debug.WriteLine($"Inner exception: {ex.InnerException.Message}");
            }
            throw; // Re-throw to let the controller handle it
        }
    }

    public async Task<FarmRecord?> GetByIdAsync(string farmId)
    {
        if (!Guid.TryParse(farmId, out var guidFarmId))
        {
            return null;
        }

        try
        {
            var farm = await _context.Farms
                .AsNoTracking()
                .FirstOrDefaultAsync(f => f.Id == guidFarmId);

            if (farm == null)
            {
                return null;
            }

            // Load related data separately
            if (farm.DistrictId.HasValue)
            {
                var district = await _context.Districts.FirstOrDefaultAsync(d => d.Id == farm.DistrictId.Value);
                farm.District = district?.Name ?? string.Empty;
            }
            else
            {
                farm.District = string.Empty;
            }

            if (!string.IsNullOrEmpty(farm.ChosenVarietyId))
            {
                var variety = await _context.PepperVarieties.FirstOrDefaultAsync(v => v.Id == farm.ChosenVarietyId);
                farm.ChosenVariety = variety?.Name ?? string.Empty;
            }
            else
            {
                farm.ChosenVariety = string.Empty;
            }

            return farm;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Error in GetByIdAsync: {ex.Message}");
            System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");
            if (ex.InnerException != null)
            {
                System.Diagnostics.Debug.WriteLine($"Inner exception: {ex.InnerException.Message}");
            }
            throw;
        }
    }

    public async Task<FarmRecord?> UpdateAsync(string farmId, FarmRecord farmRecord)
    {
        // Note: This method is kept for interface compatibility
        // The actual update logic with validation is in PlantationService.UpdateFarmAsync
        // This method should not be called directly - use the service method instead
        if (!Guid.TryParse(farmId, out var guidFarmId))
        {
            return null;
        }

        var existingFarm = await _context.Farms
            .FirstOrDefaultAsync(f => f.Id == guidFarmId);

        if (existingFarm == null)
        {
            return null;
        }

        // Update properties
        existingFarm.FarmName = farmRecord.FarmName;
        existingFarm.DistrictId = farmRecord.DistrictId;
        existingFarm.SoilTypeId = farmRecord.SoilTypeId;
        existingFarm.ChosenVarietyId = farmRecord.ChosenVarietyId;
        existingFarm.FarmStartDate = farmRecord.FarmStartDate;
        existingFarm.AreaHectares = farmRecord.AreaHectares;
        existingFarm.TotalVines = farmRecord.TotalVines;

        await _context.SaveChangesAsync();
        return existingFarm;
    }

    public async Task<bool> DeleteAsync(string farmId)
    {
        if (!Guid.TryParse(farmId, out var guidFarmId))
        {
            return false;
        }

        try
        {
            var farm = await _context.Farms
                .FirstOrDefaultAsync(f => f.Id == guidFarmId);

            if (farm == null)
            {
                return false;
            }

            _context.Farms.Remove(farm);
            var result = await _context.SaveChangesAsync();
            return result > 0;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Error in DeleteAsync: {ex.Message}");
            System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");
            if (ex.InnerException != null)
            {
                System.Diagnostics.Debug.WriteLine($"Inner exception: {ex.InnerException.Message}");
            }
            throw;
        }
    }
}

