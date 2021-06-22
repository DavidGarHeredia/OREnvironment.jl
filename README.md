# OREnvironment

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://davidgarheredia.github.io/OREnvironment.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://davidgarheredia.github.io/OREnvironment.jl/dev)


OREnvironment is a package to handle optimization problems in Julia. For the moment (no plan to change that in the short term), the package is oriented to deal with Mix Integer **Linear** Programming (MILP) problems.

The package by itself is not that useful. It is thought to be used as a base for other packages I am working on. E.g, to automatically obtain lower bounds in MILP problems.

The package basically handles constraints and solutions under a common framework (OREnvironment) so it is easier to develop solution methods, testing similar algorithms, reuse code between projects, etc. It also incorporates a couple of interesting ideas to manage everything more efficiently. See details in the documentation.

To install it:

```julia
pkg> add https://github.com/DavidGarHeredia/OREnvironment.jl.git
```

