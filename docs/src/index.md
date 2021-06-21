# Home

OREnvironment is a package to handle optimization problems in Julia. For the moment (no plan to change that in the short term), the package is oriented to deal with Mix Integer **Linear** Programming (MILP) problems.

The package by itself is not that useful. It is thought to be used as a base for other packages I am working on. E.g, to automatically obtain lower bounds in MILP problems.

The package basically handles constraints and solutions under a common framework (OREnvironment), so it is easier to develop solution methods, testing similar algorithms, reuse code between projects, etc. It also incorporates a couple of interesting ideas to manage everything more efficiently.

The structure of the documentation is as follows. First, it is exposed how to handle constraints. Then, the problem environment is presented. Finally, the frameworks to handle solution status and solutions are discussed.

To install it:

```julia
pkg> add https://github.com/DavidGarHeredia/OREnvironment.jl.git
````

!!! warning

    The code makes extensive use of the macro `@inbounds`. So be careful when accessing arrays.
