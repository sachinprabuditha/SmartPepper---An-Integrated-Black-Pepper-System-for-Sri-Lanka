using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKR_Backend_API.DTOs;
using SKR_Backend_API.Services;

namespace SKR_Backend_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PredictionController : ControllerBase
    {
        private readonly IPricePredictionService _predictionService;

        public PredictionController(IPricePredictionService predictionService)
        {
            _predictionService = predictionService;
        }

        [HttpPost("predict")]
        [ProducesResponseType(typeof(PricePredictionResult), StatusCodes.Status200OK)]
        public IActionResult Predict([FromBody] PricePredictionRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                var result = _predictionService.Predict(request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                // In production, log the exception
                return StatusCode(500, new { message = "An error occurred during prediction.", details = ex.Message });
            }
        }
    }
}
