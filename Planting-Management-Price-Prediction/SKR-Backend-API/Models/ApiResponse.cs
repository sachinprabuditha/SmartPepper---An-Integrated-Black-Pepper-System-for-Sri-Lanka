namespace SKR_Backend_API.Models;

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string Message { get; set; } = string.Empty;

    public static ApiResponse<T> SuccessResponse(T? data, string message = "Operation successful")
    {
        return new ApiResponse<T>
        {
            Success = true,
            Data = data,
            Message = message
        };
    }

    public static ApiResponse<T> SuccessResponse(string message = "Operation successful")
    {
        return new ApiResponse<T>
        {
            Success = true,
            Data = default,
            Message = message
        };
    }

    public static ApiResponse<T> ErrorResponse(string message, T? data = default)
    {
        return new ApiResponse<T>
        {
            Success = false,
            Data = data,
            Message = message
        };
    }
}

