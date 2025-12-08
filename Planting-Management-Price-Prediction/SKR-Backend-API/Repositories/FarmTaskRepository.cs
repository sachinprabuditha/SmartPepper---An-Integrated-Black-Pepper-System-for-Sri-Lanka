using Microsoft.EntityFrameworkCore;
using SKR_Backend_API.Data;
using SKR_Backend_API.Models;

namespace SKR_Backend_API.Repositories;

public class FarmTaskRepository : IFarmTaskRepository
{
    private readonly AppDbContext _context;

    public FarmTaskRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<FarmTask> CreateAsync(FarmTask task)
    {
        task.CreatedAt = DateTime.UtcNow;
        _context.FarmTasks.Add(task);
        await _context.SaveChangesAsync();
        return task;
    }

    public async Task<IEnumerable<FarmTask>> GetByFarmIdAsync(Guid farmId)
    {
        return await _context.FarmTasks
            .Where(t => t.FarmId == farmId)
            .OrderBy(t => t.DueDate)
            .ToListAsync();
    }

    public async Task<FarmTask?> GetByIdAsync(Guid taskId)
    {
        return await _context.FarmTasks
            .FirstOrDefaultAsync(t => t.Id == taskId);
    }

    public async Task<FarmTask?> UpdateAsync(Guid taskId, FarmTask task)
    {
        var existingTask = await _context.FarmTasks
            .FirstOrDefaultAsync(t => t.Id == taskId);

        if (existingTask == null)
        {
            return null;
        }

        // Update properties
        existingTask.TaskName = task.TaskName;
        existingTask.Phase = task.Phase;
        existingTask.TaskType = task.TaskType;
        existingTask.VarietyKey = task.VarietyKey;
        existingTask.DueDate = task.DueDate;
        existingTask.Status = task.Status;
        existingTask.DateCompleted = task.DateCompleted;
        existingTask.InputDetails = task.InputDetails;
        existingTask.DetailedSteps = task.DetailedSteps;
        existingTask.ReasonWhy = task.ReasonWhy;
        existingTask.IsManual = task.IsManual;
        existingTask.Priority = task.Priority;

        await _context.SaveChangesAsync();
        return existingTask;
    }

    public async Task<bool> DeleteAsync(Guid taskId)
    {
        var task = await _context.FarmTasks
            .FirstOrDefaultAsync(t => t.Id == taskId);

        if (task == null)
        {
            return false;
        }

        _context.FarmTasks.Remove(task);
        var result = await _context.SaveChangesAsync();
        return result > 0;
    }

    public async Task<bool> DeleteByFarmIdAsync(Guid farmId)
    {
        try
        {
            var tasks = await _context.FarmTasks
                .Where(t => t.FarmId == farmId)
                .ToListAsync();

            if (tasks.Count == 0)
            {
                // No tasks to delete is not an error - return true
                return true;
            }

            _context.FarmTasks.RemoveRange(tasks);
            var result = await _context.SaveChangesAsync();
            return result > 0;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Error in DeleteByFarmIdAsync: {ex.Message}");
            System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");
            if (ex.InnerException != null)
            {
                System.Diagnostics.Debug.WriteLine($"Inner exception: {ex.InnerException.Message}");
            }
            throw;
        }
    }
}

