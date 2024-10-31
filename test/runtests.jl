# test/runtests.jl
using Test
using LinkedInAPI
using HTTP
using JSON

#= 
Test utilities and mock structures
=#
mutable struct MockResponse
    status::Int
    body::Vector{UInt8}
    headers::Vector{Pair{String,String}}
end

# Mock responses
const MOCK_USER_INFO = Dict(
    "sub" => "1234567890",
    "name" => "Test User",
    "email" => "test@example.com"
)

const MOCK_REGISTER_RESPONSE = Dict(
    "value" => Dict(
        "uploadMechanism" => Dict(
            "com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest" => Dict(
                "uploadUrl" => "https://example.com/upload"
            )
        ),
        "asset" => "urn:li:digitalmediaAsset:1234567890"
    )
)

# Define mock response type conversion
Base.String(r::MockResponse) = String(r.body)
HTTP.header(r::MockResponse, key::String) = get(Dict(r.headers), key, "")

# Define top-level mock functions
function mock_get_userinfo(url::String, headers::Vector{Pair{String,String}})
    if url == "https://api.linkedin.com/v2/userinfo"
        return MockResponse(200, Vector{UInt8}(JSON.json(MOCK_USER_INFO)), [])
    end
    error("Unexpected URL in mock: $url")
end

function mock_get_error(url::String, headers::Vector{Pair{String,String}})
    throw(HTTP.StatusError(401, "GET", url, MockResponse(401, Vector{UInt8}("Unauthorized"), [])))
end

function mock_post_request(url::String, headers::Vector{Pair{String,String}}, body)
    if url == "https://api.linkedin.com/v2/assets?action=registerUpload"
        return MockResponse(200, Vector{UInt8}(JSON.json(MOCK_REGISTER_RESPONSE)), [])
    elseif url == "https://example.com/upload"
        return MockResponse(201, Vector{UInt8}(""), [])
    elseif url == "https://api.linkedin.com/v2/ugcPosts"
        return MockResponse(201, Vector{UInt8}(""), ["X-RestLi-Id" => "post12345"])
    end
    error("Unexpected URL in mock: $url")
end

@testset "LinkedInAPI" begin
    @testset "Configuration" begin
        # Test missing environment variables
        delete!(ENV, "LINKEDIN_ACCESS_TOKEN")
        @test_throws ErrorException LinkedInConfig()
        
        # Test with access token but no image directory
        ENV["LINKEDIN_ACCESS_TOKEN"] = "test_token"
        delete!(ENV, "LINKEDIN_IMAGE_DIRECTORY")
        config = LinkedInConfig()
        @test config.access_token == "test_token"
        @test isdir(config.image_directory)  # Should create default directory
        
        # Test with both variables set
        test_dir = mktempdir()
        ENV["LINKEDIN_IMAGE_DIRECTORY"] = test_dir
        config = LinkedInConfig()
        @test config.access_token == "test_token"
        @test config.image_directory == ENV["LINKEDIN_IMAGE_DIRECTORY"]
    end

    @testset "User Info" begin
        config = LinkedInConfig()
        
        # Store original method
        original_get = getfield(HTTP, :get)
        
        try
            # Replace HTTP.get with mock version
            Core.eval(HTTP, :(get(url::String, headers::Vector{Pair{String,String}}) = 
                $mock_get_userinfo(url, headers)))
            
            result = LinkedInAPI.get_linkedin_info(config)
            @test result["OK"] == true
            @test result["urn"] == "urn:li:person:1234567890"
            @test result["name"] == "Test User"
            @test result["email"] == "test@example.com"
        finally
            # Restore original method
            Core.eval(HTTP, :(get = $original_get))
        end
    end

    @testset "Image Operations" begin
        config = LinkedInConfig()
        
        # Create test image
        test_image_path = joinpath(config.image_directory, "test.jpg")
        write(test_image_path, "fake image content")
        
        # Store original method
        original_post = getfield(HTTP, :post)
        
        try
            # Replace HTTP.post with mock version
            Core.eval(HTTP, :(post(url::String, headers::Vector{Pair{String,String}}, body) = 
                $mock_post_request(url, headers, body)))
            
            # Test register_image_upload
            response = LinkedInAPI.register_image_upload(config, "urn:li:person:1234567890")
            @test haskey(response, "value")
            @test response["value"]["asset"] == "urn:li:digitalmediaAsset:1234567890"
            
            # Test upload_image
            success = LinkedInAPI.upload_image(
                "https://example.com/upload",
                config,
                "test.jpg"
            )
            @test success == true
        finally
            # Cleanup
            Core.eval(HTTP, :(post = $original_post))
            rm(test_image_path, force=true)
        end
    end

    @testset "Share Post" begin
        config = LinkedInConfig()
        
        # Create test image
        test_image_path = joinpath(config.image_directory, "test.jpg")
        write(test_image_path, "fake image content")
        
        # Store original methods
        original_get = getfield(HTTP, :get)
        original_post = getfield(HTTP, :post)
        
        try
            # Replace HTTP methods with mock versions
            Core.eval(HTTP, :(get(url::String, headers::Vector{Pair{String,String}}) = 
                $mock_get_userinfo(url, headers)))
            Core.eval(HTTP, :(post(url::String, headers::Vector{Pair{String,String}}, body) = 
                $mock_post_request(url, headers, body)))
            
            result = linkedinshare(
                config,
                "Test Post",
                "Test Content",
                "https://example.com",
                ["test", "julia"],
                "PUBLIC",
                "test.jpg"
            )
            
            @test result["OK"] == true
            @test result["post_id"] == "post12345"
            @test result["message"] == "Post shared successfully with image!"
        finally
            # Cleanup
            Core.eval(HTTP, :(get = $original_get))
            Core.eval(HTTP, :(post = $original_post))
            rm(test_image_path, force=true)
        end
    end

    @testset "Error Handling" begin
        config = LinkedInConfig()
        
        # Store original method
        original_get = getfield(HTTP, :get)
        
        try
            # Replace HTTP.get with error mock version
            Core.eval(HTTP, :(get(url::String, headers::Vector{Pair{String,String}}) = 
                $mock_get_error(url, headers)))
            
            result = LinkedInAPI.get_linkedin_info(config)
            @test result["OK"] == false
            @test contains(result["message"], "Error getting URN")
        finally
            # Restore original method
            Core.eval(HTTP, :(get = $original_get))
        end
    end
end