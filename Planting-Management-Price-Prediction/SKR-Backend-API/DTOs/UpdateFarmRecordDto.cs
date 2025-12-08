using System.ComponentModel.DataAnnotations;

namespace SKR_Backend_API.DTOs;

public class UpdateFarmRecordDto
{
    [StringLength(200)]
    public string? FarmName { get; set; }

    public int? DistrictId { get; set; }

    public int? SoilTypeId { get; set; }

    [StringLength(50)]
    public string? ChosenVarietyId { get; set; }

    public DateTime? FarmStartDate { get; set; }

    [Range(0.01, double.MaxValue, ErrorMessage = "Area must be greater than 0")]
    public double? AreaHectares { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Total vines must be at least 1")]
    public int? TotalVines { get; set; }
}

