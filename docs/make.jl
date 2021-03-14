push!(LOAD_PATH,"../")

using Documenter, OREnvironment

makedocs(sitename="OREnvironment.jl", 
format = Documenter.HTML(prettyurls = false)
)
