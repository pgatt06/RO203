# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(path)

    # Create the model
    m = Model(CPLEX.Optimizer)

    # TODO
    #    "..//data//instanceTest.txt"
    A = readInputFile(path)
    n,p = size(A)
    #Variable à définir : Xij
    @variable(m, X[1:n+2,1:p+2], Bin)
    @variable(m, K[1:n,1:p]>=0, Int )

    for i in 1:n+2
        @constraint(m, X[i, 1] == 0)
        @constraint(m, X[i, p+2] == 0)
    end
    for j in 2:p+1
        @constraint(m, X[1, j] == 0)
        @constraint(m, X[n+2, j] == 0)
    end
    
    for i in 2:n+1
        for j in 2:p+1
            @constraint(m, A[i-1, j-1] + X[i-1,j] + X[i+1, j] + X[i, j-1]+ X[i, j+1]+ X[i, j] - 2*K[i-1,j-1] == 0)
        end
    end

    @objective(m, Min, 1)
    



    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)
    solFound = primal_status(m) == MOI.FEASIBLE_POINT
    if solFound
        vX = JuMP.value.(X)
        return solFound, time() - start, vX
    end
    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return solFound, time() - start, 0
    
end




# solFound, t, vX = cplexSolve("data//instanceTest.txt")
# A = readInputFile("data//instanceTest.txt")
# displayGrid(A)
# if solFound
#     println("\nSolution trouvé en ", t, "s :\n")
#     displaySolution(vX)
# else
#     println("Pas de solution trouvé.")

# end


"""
Heuristically solve an instance
"""

function heuristic(State::Matrix)

    n,m = size(State)
    score = 0
    for i in 1:n
        for j in 1:m    
            score += State[i,j]
        end
    end
    return score
end

function keyFromMatrix(A::Matrix)
    concatenated_string = ""
    n,m = size(A)
    # Parcourir chaque élément de la matrice
    for i in 1:n
        for j in 1:m  
            # Convertir l'entier en chaîne de caractères et l'ajouter à la chaîne concaténée
            concatenated_string *= string(A[i,j])
        end
    end
    
    return concatenated_string
end

function getNeighbor(A, path)
    l = []
    n,m = size(A)
    # Parcourir chaque élément de la matrice
    for i in 1:n
        for j in 1:m  
            A2 = copy(A)
            path2 = copy(path)
            # Inverser la valeur de l'élément actuel
            A2[i, j] = 1 - A[i, j]
            path2[i,j] =!path[i,j]
            # Convertir l'entier en chaîne de caractères et l'ajouter à la chaîne concaténée
            if i > 1
                A2[i - 1, j] = 1 - A[i - 1, j]
            end
            if i < n
                A2[i + 1, j] = 1 - A[i + 1, j]
            end
            if j > 1
                A2[i, j - 1] = 1 - A[i, j - 1]
            end
            if j < m
                A2[i, j + 1] = 1 - A[i, j + 1]
            end


            # Ajouter la matrice modifiée à la liste
            push!(l, [A2, path2])
        end
    end
    
    return l
end

function insertCouple!(queue, couple)
    i = searchsortedfirst([x[2] for x in queue], couple[2])
    insert!(queue, i, couple)
end

function heuristicSolve(path)
    A = readInputFile(path)
    start = time()
    n,m = size(A)
    path = falses((n,m))
    dict = Dict(keyFromMatrix(A)=>path)
    queue = []
    state = A
    
    
    
    pp = 0
    while true
        l = getNeighbor(state, path)
        for c in l
            A2 = c[1]
            path2 = c[2]
            s = keyFromMatrix(A2)
            h = heuristic(A2)
            if !(s in keys(dict))
                dict[s] = path2
                insertCouple!(queue, [A2, h])
            end
        end
        
        couple = popfirst!(queue)
        if couple[2] == 0
            return true, time()-start, dict[keyFromMatrix(couple[1])]
        else
            state = couple[1]
            path = dict[keyFromMatrix(state)]
        end
        pp = pp+1
        print(pp, " ")
        if time()-start>30
            return false, time()-start, 0
        end

    end
end


"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""



function solveDataSet()

    dataFolder = "data/"
    resFolder = "res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex", "heuristic"]
    #resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder)) 
        
        print("-- Resolution of ", file, "\n")
        s = dataFolder * '/' * file

        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if isfile(outputFile)
                rm(outputFile)                
            end
            fout = open(outputFile, "w")

            resolutionTime = -1
            isOptimal = false
            
            # If the method is cplex
            if resolutionMethod[methodId] == "cplex"
                
                
                # Solve it and get the results
                solFound, t, vX = cplexSolve(s)
                
                # If a solution is found, write it
                if solFound
                    # TODO
                    println(fout, " resolution time for cplex :\n", t)
                    println(fout, "\n\nvalue of the solution :\n", vX)

                else 
                    println(fout, "Pas de solution trouvée\n")
                end

                # If the method is one of the heuristics
            else
                print("TESTTTT")
                isSolved = false

                # Start a chronometer 
                startingTime = time()
                
                # While the grid is not solved and less than 100 seconds are elapsed
                while !isOptimal && resolutionTime < 100
                    
                    # TODO 
                    println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime, vX = heuristicSolve(s)

                    if solFound
                        # TODO
                        println(fout, " resolution time for heuristic :\n", resolutionTime)
                        println(fout, "\n\nvalue of the solution :\n", vX)
    
                    else 
                        println(fout, "Pas de solution trouvée\n")
                    end
                    
                end

                # Write the solution (if any)
                if isOptimal

                    # TODO
                    println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                    
                    
                end 
            end
        
            
            # TODO
            println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
            close(fout)

        end
            # Display the results obtained with the method on the current instance
            # include(outputFile)

            # println(resolutionMethod[methodId], " optimal: ", isOptimal)
            # println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")        
    end 
end

solveDataSet()
