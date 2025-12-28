using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using SKR_Backend_API.DTOs;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace SKR_Backend_API.Services
{
    public interface IPricePredictionService
    {
        PricePredictionResult Predict(PricePredictionRequest request);
    }

    public class PricePredictionService : IPricePredictionService
    {
        private readonly InferenceSession _session;

        // Locations in specific order as per model requirement
        private static readonly string[] OrderedLocations = new[] 
        { 
            "Colombo", "Galle", "Hambantota", "Kandy", "Kegalle", 
            "Kurunegala", "Matale", "Matara", "Monaragala" 
        };

        public PricePredictionService(IWebHostEnvironment env)
        {
            var modelPath = Path.Combine(env.ContentRootPath, "Models", "multi_output_regressor_model.onnx");
            if (!File.Exists(modelPath))
            {
                throw new FileNotFoundException($"Model file not found at {modelPath}");
            }
            _session = new InferenceSession(modelPath);
        }

        public PricePredictionResult Predict(PricePredictionRequest request)
        {
            var inputs = new List<float>();

            // 1. USD_Buy_Rate
            inputs.Add((float)request.UsdBuyRate);
            // 2. USD_Sell_Rate
            inputs.Add((float)request.UsdSellRate);
            // 3. Temperature
            inputs.Add((float)request.Temperature);
            // 4. Precipitation
            inputs.Add((float)request.Precipitation);
            // 5. Year
            inputs.Add((float)request.Date.Year);
            // 6. Month
            inputs.Add((float)request.Date.Month);
            // 7. Day
            inputs.Add((float)request.Date.Day);

            // 8-16. Locations
            foreach (var loc in OrderedLocations)
            {
                inputs.Add(string.Equals(request.Location, loc, StringComparison.OrdinalIgnoreCase) ? 1.0f : 0.0f);
            }

            // 17-18. Grade (GR-2, WHITE)
            // GR-1: GR-2=0, WHITE=0
            // GR-2: GR-2=1, WHITE=0
            // WHITE: GR-2=0, WHITE=1
            var isGr2 = string.Equals(request.Grade, "GR-2", StringComparison.OrdinalIgnoreCase);
            var isWhite = string.Equals(request.Grade, "WHITE", StringComparison.OrdinalIgnoreCase);

            inputs.Add(isGr2 ? 1.0f : 0.0f);
            inputs.Add(isWhite ? 1.0f : 0.0f);

            // Create tensor
            var inputTensor = new DenseTensor<float>(inputs.ToArray(), new[] { 1, inputs.Count });

            // Get input name 
            var inputName = _session.InputMetadata.Keys.First();
            var input = NamedOnnxValue.CreateFromTensor(inputName, inputTensor);

            // Run inference
            using var results = _session.Run(new[] { input });
            
            // Expected output: Highest_Price, Average_Price
            // Usually returns a tensor of shape [1, 2]
            var outputData = results.First().AsTensor<float>().ToArray();

            return new PricePredictionResult
            {
                HighestPrice = outputData[0],
                AveragePrice = outputData[1]
            };
        }
    }
}
