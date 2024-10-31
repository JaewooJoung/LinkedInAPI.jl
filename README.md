# 🚀 LinkedInAPI.jl

> Post to LinkedIn from Julia? Yes, you can! 🎉

A super cool Julia package that lets you share your awesome posts (with images!) on LinkedIn without leaving your favorite REPL. Because why switch between apps when you can do everything in Julia? 😎

## 🎯 What Can It Do?

- 📝 Share posts on LinkedIn
- 🖼️ Upload images with your posts
- #️⃣ Add cool hashtags
- 🔒 Control post visibility
- 🤓 All from your Julia REPL!

## 🔧 Installation

```julia
using Pkg
Pkg.add(url="https://github.com/JaewooJoung/LinkedInAPI.jl")
```

## 🏃‍♂️ Quick Start

First, let's set up your secret stuff:

```bash
# Windows (PowerShell is cool 😎)
$env:LINKEDIN_ACCESS_TOKEN = "your_super_secret_token"
$env:LINKEDIN_IMAGE_DIRECTORY = "C:\path\to\your\awesome\images"
```

Now, let's post something awesome!

```julia
using LinkedInAPI

# Let's configure! 🛠️
config = LinkedInConfig()

# Time to share something cool! 🎨
result = linkedinshare(
    config,
    "Julia is Awesome!",
    "Check out this cool package I just made! 🚀",
    "https://github.com/JaewooJoung/LinkedInAPI.jl",
    ["JuliaLang", "OpenSource", "CodingIsFun"],
    "PUBLIC",
    "cool-screenshot.png"
)

# Did it work? 🤔
result["OK"] ? println("🎉 Woohoo! Posted!") : println("😅 Oops: $(result["message"])")
```

## 🌟 Full Example

Here's a complete example that you can copy-paste and modify:

```julia
using Pkg
Pkg.activate(".")  
using LinkedInAPI

# Get ready to be awesome
config = LinkedInConfig()

# Your amazing content
title = "🎉 Exciting News!"
url = "https://github.com/JaewooJoung/LinkedInAPI.jl"
content = """
🚀 Just launched my new Julia package LinkedInAPI.jl!

📱 Now you can post to LinkedIn directly from Julia.
Pretty cool, right? 😎

🔗 Check it out at: $url
"""
hashtags = ["JuliaLang", "OpenSource", "Programming"]
image_filename = "스크린샷 2024-10-31 125346.png"

# Share the awesomeness
println("🎯 Getting ready to share...")
result = linkedinshare(
    config,
    title,
    content,
    url,
    hashtags,
    "PUBLIC",
    image_filename
)

# Let's see what happened
if result["OK"]
    println("🎊 Success! Your post is live!")
    println("📝 Post ID: $(result["post_id"])")
else
    println("😅 Oops! Something went wrong")
    println("❌ Error: $(result["message"])")
end
```

## 🛠️ Requirements

- Julia 1.6 or newer (because we like to stay fresh!)
- A LinkedIn API access token (your secret key to LinkedIn's heart ❤️)
- A folder for your images (keep them organized! 📁)

## 📦 Dependencies

We stand on the shoulders of giants:
- HTTP.jl (for talking to LinkedIn)
- JSON.jl (for making sense of LinkedIn's replies)

## 🤔 Common Issues

1. **"Where's my token?"** 
   - Did you set `LINKEDIN_ACCESS_TOKEN`? LinkedIn needs to know it's you!

2. **"Can't find my images!"**
   - Is `LINKEDIN_IMAGE_DIRECTORY` pointing to the right place? Those memes won't post themselves!

3. **"It's not working!"**
   - Double-check your image filename (yes, even the Korean characters in '스크린샷'!)
   - Make sure your token hasn't expired (they like to do that sometimes 😅)

## 👨‍💻 Author

Made with ❤️ and lots of ☕ by:

**Jaewoo Joung**  
📧 jaewoo.joung@outlook.com  
🐙 GitHub: [@JaewooJoung](https://jaewoojoung.github.io/markdown/me.html)

## 📄 License

MIT License (aka go wild, just remember where you got it! 😉)

## 🤝 Contributing

Got ideas? Found a bug? Want to make this even more awesome?

1. Fork it! 🍴
2. Create your feature branch: `git checkout -b my-cool-feature`
3. Commit your changes: `git commit -am 'Added some coolness'`
4. Push to the branch: `git push origin my-cool-feature`
5. Submit a PR! 🎉

## 💡 Get Your LinkedIn Token

1. Visit [LinkedIn Developer Portal](https://www.linkedin.com/developers/)
2. Create a new app (it's easy, promise!)
3. Ask for these permissions:
4. Get your token
5. Keep it secret, keep it safe! 🧙‍♂️

---

Made with Julia 💜 in 2024  
Because social media should be programmable! 🚀