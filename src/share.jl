# src/share.jl
#=
Register an image upload with LinkedIn's API

Parameters:
- config: LinkedInConfig instance with access token
- person_urn: LinkedIn user URN

Returns the registration response or nothing if registration fails
=#
function register_image_upload(config::LinkedInConfig, person_urn::String)
    register_url = "https://api.linkedin.com/v2/assets?action=registerUpload"
    
    headers = [
        "Authorization" => "Bearer $(config.access_token)",
        "X-Restli-Protocol-Version" => "2.0.0",
        "Content-Type" => "application/json"
    ]
    
    register_data = Dict(
        "registerUploadRequest" => Dict(
            "recipes" => ["urn:li:digitalmediaRecipe:feedshare-image"],
            "owner" => person_urn,
            "serviceRelationships" => [
                Dict(
                    "relationshipType" => "OWNER",
                    "identifier" => "urn:li:userGeneratedContent"
                )
            ]
        )
    )
    
    try
        response = HTTP.post(register_url, headers, JSON.json(register_data))
        return JSON.parse(String(response.body))
    catch e
        @error "Error registering image upload" exception=e
        return nothing
    end
end

#=
Upload an image to LinkedIn using the provided upload URL

Parameters:
- upload_url: URL provided by the registration response
- config: LinkedInConfig instance with access token
- image_filename: Name of the image file in the configured directory

Returns true if successful, false otherwise
=#
function upload_image(upload_url::String, config::LinkedInConfig, image_filename::String)
    headers = [
        "Authorization" => "Bearer $(config.access_token)"
    ]
    
    image_path = joinpath(config.image_directory, image_filename)
    
    try
        if !isfile(image_path)
            error("Image file not found: $image_path")
        end
        image_data = read(image_path)
        response = HTTP.post(upload_url, headers, image_data)
        return response.status == 201
    catch e
        @error "Error uploading image" exception=e
        return false
    end
end

#=
Share a post on LinkedIn with an image

Parameters:
- config: LinkedInConfig with access token and image directory
- title: Title of the post
- content: Main content of the post
- url: URL to include in the post
- hashtags: List of hashtags (without #)
- visibility: Post visibility ("PUBLIC" or "CONNECTIONS")
- image_filename: Name of the image file in the configured directory

Returns Dict with:
- "OK": Boolean indicating success
- "message": Status message
- "post_id": ID of the created post (if successful)

Example:
```julia
config = LinkedInConfig()
result = linkedinshare(
    config,
    "My Post",
    "Content here",
    "https://example.com",
    ["hashtag1", "hashtag2"],
    "PUBLIC",
    "image.jpg"
)
```
=#
function linkedinshare(config::LinkedInConfig, title::String, content::String, url::String, 
                      hashtags::Vector{String}, visibility::String, image_filename::String)
    user_info = get_linkedin_info(config)
    
    if !user_info["OK"]
        return Dict("OK" => false, "message" => user_info["message"])
    end
    
    register_response = register_image_upload(config, user_info["urn"])
    if register_response === nothing
        return Dict("OK" => false, "message" => "Failed to register image upload")
    end
    
    upload_url = register_response["value"]["uploadMechanism"]["com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest"]["uploadUrl"]
    asset = register_response["value"]["asset"]
    
    if !upload_image(upload_url, config, image_filename)
        return Dict("OK" => false, "message" => "Failed to upload image")
    end
    
    share_url = "https://api.linkedin.com/v2/ugcPosts"
    headers = [
        "Authorization" => "Bearer $(config.access_token)",
        "X-Restli-Protocol-Version" => "2.0.0",
        "Content-Type" => "application/json"
    ]
    
    hashtag_text = join(map(tag -> "#$tag", hashtags), " ")
    
    share_content = Dict(
        "author" => user_info["urn"],
        "lifecycleState" => "PUBLISHED",
        "specificContent" => Dict(
            "com.linkedin.ugc.ShareContent" => Dict(
                "shareCommentary" => Dict(
                    "text" => "$title\n\n$content\n\n$hashtag_text"
                ),
                "shareMediaCategory" => "IMAGE",
                "media" => [
                    Dict(
                        "status" => "READY",
                        "description" => Dict("text" => content),
                        "media" => asset,
                        "title" => Dict("text" => title)
                    )
                ]
            )
        ),
        "visibility" => Dict(
            "com.linkedin.ugc.MemberNetworkVisibility" => visibility
        )
    )
    
    try
        response = HTTP.post(share_url, headers, JSON.json(share_content))
        
        if response.status == 201
            return Dict(
                "OK" => true,
                "message" => "Post shared successfully with image!",
                "post_id" => HTTP.header(response, "X-RestLi-Id")
            )
        else
            return Dict(
                "OK" => false,
                "message" => "Share failed with status: $(response.status)"
            )
        end
    catch e
        error_msg = isa(e, HTTP.ExceptionRequest.StatusError) ? String(e.response.body) : string(e)
        return Dict("OK" => false, "message" => error_msg)
    end
end