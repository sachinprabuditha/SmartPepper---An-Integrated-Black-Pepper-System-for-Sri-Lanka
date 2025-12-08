using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKR_Backend_API.Models;

[Table("Farms")]
public class FarmRecord
{
    [Key]
    [Column("id")]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    [Column("userid")]
    public Guid UserId { get; set; }

    [Required]
    [MaxLength(255)]
    [Column("farmname")]
    public string FarmName { get; set; } = string.Empty;

    [Column("districtid")]
    public int? DistrictId { get; set; }

    [Column("soiltypeid")]
    public int? SoilTypeId { get; set; }

    [MaxLength(50)]
    [Column("chosenvarietyid")]
    public string? ChosenVarietyId { get; set; }

    // Keep District and ChosenVariety as computed properties for backward compatibility
    [NotMapped]
    public string District { get; set; } = string.Empty;

    [NotMapped]
    public string ChosenVariety { get; set; } = string.Empty;

    [Column("farmstartdate", TypeName = "timestamp with time zone")]
    public DateTime? FarmStartDate { get; set; }

    [Column("areahectares", TypeName = "numeric")]
    public decimal? AreaHectares { get; set; }

    [Column("totalvines")]
    public int? TotalVines { get; set; }

    [Column("createdat", TypeName = "timestamp with time zone")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties (configured via Fluent API in AppDbContext)
    public District? DistrictNavigation { get; set; }

    public SoilType? SoilTypeNavigation { get; set; }

    public BlackPepperVariety? VarietyNavigation { get; set; }
}

