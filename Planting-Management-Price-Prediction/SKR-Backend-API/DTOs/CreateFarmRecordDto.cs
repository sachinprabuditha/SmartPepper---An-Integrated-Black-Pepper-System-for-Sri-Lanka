using System.ComponentModel.DataAnnotations;

namespace SKR_Backend_API.DTOs;

public class CreateFarmRecordDto
{
    [Required]
    [StringLength(200)]
    public string FarmName { get; set; } = string.Empty;

    [Required]
    public int DistrictId { get; set; }

    [Required]
    public int SoilTypeId { get; set; }

    [Required]
    [StringLength(50)]
    public string ChosenVarietyId { get; set; } = string.Empty;

    [Required]
    public DateTime FarmStartDate { get; set; }

    [Required]
    [Range(0.01, double.MaxValue, ErrorMessage = "Area must be greater than 0")]
    public double AreaHectares { get; set; }

    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "Total vines must be at least 1")]
    public int TotalVines { get; set; }
}

