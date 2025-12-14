using System.ComponentModel.DataAnnotations;

namespace SKR_Backend_API.DTOs;

public class UpdateSeasonDto
{
    [StringLength(100, MinimumLength = 1, ErrorMessage = "Season name must be between 1 and 100 characters")]
    public string? SeasonName { get; set; }

    [Range(1, 12, ErrorMessage = "Start month must be between 1 and 12")]
    public int? StartMonth { get; set; }

    [Range(2000, 2100, ErrorMessage = "Start year must be between 2000 and 2100")]
    public int? StartYear { get; set; }

    [Range(1, 12, ErrorMessage = "End month must be between 1 and 12")]
    public int? EndMonth { get; set; }

    [Range(2000, 2100, ErrorMessage = "End year must be between 2000 and 2100")]
    public int? EndYear { get; set; }

    public string? FarmId { get; set; }
}

