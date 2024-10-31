using LinkedInAPI

# Initialize configuration (uses system environment variables)
config = LinkedInConfig()

# Post details
title = "Exciting News!"
url = "https://github.com/YourUsername/LinkedInAPI.jl"
content = """
Just launched my new Julia package LinkedInAPI.jl!

This package makes it easy to post updates to LinkedIn from Julia.
Check it out at: $url
"""
hashtags = ["JuliaLang", "OpenSource", "Programming"]
image_filename = "스크린샷 2024-10-31 125346.png"

# Share the post
println("📤 Sharing post to LinkedIn...")
result = linkedinshare(
    config,
    title,
    content,
    url,
    hashtags,
    "PUBLIC",
    image_filename
)

# Show result
if result["OK"]
    println("✅ Post shared successfully!")
    println("Post ID: $(result["post_id"])")
else
    println("❌ Failed to share post")
    println("Error: $(result["message"])")
end