using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace SKR_Backend_API.Models;

[Table("FarmTasks")]
public class FarmTask
{
    [Key]
    [Column("id")]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    [Column("farmid")]
    public Guid FarmId { get; set; }

    [Required]
    [MaxLength(255)]
    [Column("taskname")]
    public string TaskName { get; set; } = string.Empty;

    [MaxLength(50)]
    [Column("phase")]
    public string Phase { get; set; } = string.Empty;

    [MaxLength(50)]
    [Column("tasktype")]
    public string TaskType { get; set; } = string.Empty;

    [MaxLength(50)]
    [Column("varietykey")]
    public string VarietyKey { get; set; } = string.Empty;

    [Column("duedate", TypeName = "timestamp with time zone")]
    public DateTime DueDate { get; set; }

    [MaxLength(20)]
    [Column("status")]
    public string Status { get; set; } = "Scheduled"; // Scheduled, Completed, Overdue

    [Column("datecompleted", TypeName = "timestamp with time zone")]
    public DateTime? DateCompleted { get; set; }

    [Column("inputdetails", TypeName = "jsonb")]
    [JsonIgnore]
    public string? InputDetailsJson { get; set; }

    [NotMapped]
    public InputDetails? InputDetails
    {
        get => string.IsNullOrEmpty(InputDetailsJson) 
            ? null 
            : System.Text.Json.JsonSerializer.Deserialize<InputDetails>(InputDetailsJson);
        set => InputDetailsJson = value == null 
            ? null 
            : System.Text.Json.JsonSerializer.Serialize(value);
    }

    [Column("detailedsteps", TypeName = "jsonb")]
    [JsonIgnore]
    public string? DetailedStepsJson { get; set; }

    [NotMapped]
    public List<string> DetailedSteps
    {
        get => string.IsNullOrEmpty(DetailedStepsJson) 
            ? new List<string>() 
            : System.Text.Json.JsonSerializer.Deserialize<List<string>>(DetailedStepsJson) ?? new List<string>();
        set => DetailedStepsJson = value == null || value.Count == 0
            ? null
            : System.Text.Json.JsonSerializer.Serialize(value);
    }

    [Column("reasonwhy", TypeName = "text")]
    public string? ReasonWhy { get; set; }

    [Column("ismanual")]
    public bool IsManual { get; set; } = false;

    [MaxLength(20)]
    [Column("priority")]
    public string Priority { get; set; } = "Medium"; // Low, Medium, High, Emergency

    [Column("createdat", TypeName = "timestamp with time zone")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class InputDetails
{
    [JsonPropertyName("items")]
    public List<InputItem> Items { get; set; } = new();

    [JsonPropertyName("labor_hours")]
    public double LaborHours { get; set; }

    [JsonPropertyName("notes")]
    public string? Notes { get; set; }
}

public class InputItem
{
    [JsonPropertyName("item_name")]
    public string ItemName { get; set; } = string.Empty;

    [JsonPropertyName("quantity")]
    public double Quantity { get; set; }

    [JsonPropertyName("unit_cost_lkr")]
    public double? UnitCostLKR { get; set; }

    [JsonPropertyName("unit")]
    public string Unit { get; set; } = "kg";
}

