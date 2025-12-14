using System.ComponentModel.DataAnnotations;

namespace SKR_Backend_API.DTOs;

public class CreateSeasonDto
{
    [Required(ErrorMessage = "Season name is required")]
    [StringLength(100, MinimumLength = 1, ErrorMessage = "Season name must be between 1 and 100 characters")]
    public string SeasonName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Start month is required")]
    [Range(1, 12, ErrorMessage = "Start month must be between 1 and 12")]
    public int StartMonth { get; set; }

    [Required(ErrorMessage = "Start year is required")]
    [Range(2000, 2100, ErrorMessage = "Start year must be between 2000 and 2100")]
    public int StartYear { get; set; }

    [Required(ErrorMessage = "End month is required")]
    [Range(1, 12, ErrorMessage = "End month must be between 1 and 12")]
    public int EndMonth { get; set; }

    [Required(ErrorMessage = "End year is required")]
    [Range(2000, 2100, ErrorMessage = "End year must be between 2000 and 2100")]
    public int EndYear { get; set; }

    [Required(ErrorMessage = "Farm ID is required")]
    public string FarmId { get; set; } = string.Empty;

    [Required(ErrorMessage = "Created by (userId) is required")]
    public string CreatedBy { get; set; } = string.Empty;
}

