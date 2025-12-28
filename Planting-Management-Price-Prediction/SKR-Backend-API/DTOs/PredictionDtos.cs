using System.ComponentModel.DataAnnotations;

namespace SKR_Backend_API.DTOs
{
    public class PricePredictionRequest
    {
        [Required]
        public double UsdBuyRate { get; set; }
        
        [Required]
        public double UsdSellRate { get; set; }
        
        [Required]
        public double Temperature { get; set; }
        
        [Required]
        public double Precipitation { get; set; }
        
        [Required]
        public DateTime Date { get; set; }
        
        [Required]
        public string Location { get; set; } = string.Empty;
        
        [Required]
        public string Grade { get; set; } = string.Empty;
    }

    public class PricePredictionResult
    {
        public float HighestPrice { get; set; }
        public float AveragePrice { get; set; }
        public string Currency { get; set; } = "LKR";
    }
}
