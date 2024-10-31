# src/config.jl
#=
Configuration struct for LinkedIn API
Handles:
- Access token management via environment variables
- Image directory configuration
=#
struct LinkedInConfig
    access_token::String
    image_directory::String
    
    function LinkedInConfig()
        access_token = get(ENV, "LINKEDIN_ACCESS_TOKEN") do
            error("LINKEDIN_ACCESS_TOKEN environment variable is not set")
        end
        
        image_directory = get(ENV, "LINKEDIN_IMAGE_DIRECTORY") do
            default_dir = joinpath(homedir(), "linkedin_images")
            @warn "LINKEDIN_IMAGE_DIRECTORY not set, using default: $default_dir"
            mkpath(default_dir)
            default_dir
        end
        
        new(access_token, image_directory)
    end
end