# src/LinkedInAPI.jl
module LinkedInAPI

using HTTP
using JSON

export LinkedInConfig, linkedinshare

include("config.jl")
include("auth.jl")
include("share.jl")
""
end





