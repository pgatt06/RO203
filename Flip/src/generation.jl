# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64, density::Float64)

    A = rand(Float64, n, n)
    A = (A .<= density) * 1
    return A
    
end 

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # TODO
    for ind in 1:10
        name = "instance" * string(ind) * ".txt"

        n = rand(5:20)
        density = rand()
        A = generateInstance(n, density)

        # Ouvrir un fichier en mode écriture
        file = open("data//" * name, "w")

        # Écrire du texte dans le fichier

        write(file, string(n)*","*string(n)*"\n")
        for i in 1:n
            line = ""
            for j in 1:n-1
                line = line * string(A[i, j]) * ","
            end
            line = line * string(A[i, n])
            write(file, line * "\n")
        end



        close(file)
    end

        # Fermer le fichier


    
end


generateDataSet()