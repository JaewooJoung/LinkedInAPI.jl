# src/auth.jl
#=
Retrieves LinkedIn user information using the provided configuration
Returns a Dict containing:
- "OK": Boolean indicating success
- "urn": User's LinkedIn URN if successful
- "name": User's name if available
- "email": User's email if available
- "message": Error message if unsuccessful
=#
function get_linkedin_info(config::LinkedInConfig)
    userinfo_url = "https://api.linkedin.com/v2/userinfo"
    headers = ["Authorization" => "Bearer $(config.access_token)"]
    
    try
        response = HTTP.get(userinfo_url, headers)
        user_data = JSON.parse(String(response.body))
        
        if haskey(user_data, "sub")
            return Dict(
                "OK" => true,
                "urn" => "urn:li:person:$(user_data["sub"])",
                "name" => get(user_data, "name", ""),
                "email" => get(user_data, "email", "")
            )
        else
            return Dict(
                "OK" => false,
                "message" => "Could not find URN in response"
            )
        end
    catch e
        error_msg = isa(e, HTTP.ExceptionRequest.StatusError) ? String(e.response.body) : string(e)
        return Dict(
            "OK" => false,
            "message" => "Error getting URN: $error_msg"
        )
    end
end