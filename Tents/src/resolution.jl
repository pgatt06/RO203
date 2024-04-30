# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

function cplexSolve(path)

    # Create the model
    m = Model(CPLEX.Optimizer)

    # TODO
    A,cont_d, cont_b = readInputFile(path)
    n,p = size(A)

    displayGrid(A,cont_d, cont_b)

    @variable(m, X[1:n+2,1:p+2], Bin)
    @variable(m, dom_h[1:n, 1:p], Bin)
    @variable(m, dom_v[1:n, 1:p], Bin)

    @variable(m, dom_h_aux[1:n, 1:p], Bin)
    @variable(m, dom_v_aux[1:n, 1:p], Bin)

    #Vaut 1 si il y a un arbre sur la case ou (exclusif sur la case de droite)
    @variable(m, A_et_droite[1:n, 1:p], Bin)
    #Vaut 1 si il y a un arbre sur la case ou (exclusif sur la case de droite)
    @variable(m, X_et_droite[1:n, 1:p], Bin)
    #Vaut 1 si il y a un arbre sur la case ou (exclusif sur la case de bas)
    @variable(m, A_et_bas[1:n, 1:p], Bin)
    #Vaut 1 si il y a un arbre sur la case ou (exclusif sur la case de bas)
    @variable(m, X_et_bas[1:n, 1:p], Bin)

    @variable(m, quotient_X_h[1:n, 1:p-1], Int)
    @variable(m, quotient_X_v[1:n-1, 1:p], Int)
    @variable(m, quotient_A_h[1:n, 1:p-1], Int)
    @variable(m, quotient_A_v[1:n-1, 1:p], Int)

    for i in 2:n+1
        for j in 2:p+1
            @constraint(m, X[i, j] + X[i+1, j] <= 1)
            @constraint(m, X[i, j] + X[i, j+1] <= 1)
            @constraint(m, X[i, j] + X[i+1, j+1] <= 1)
        end
    end

    for i in 2:n+1
        @constraint(m, sum(X[i,j] for j in 2:p+1) == cont_d[i-1])
    end

    for j in 2:p+1
        @constraint(m, sum(X[i,j] for i in 2:n+1) == cont_b[j-1])
    end

    for i in 1:n
        for j in 1:p
            @constraint(m, A[i, j] + X[i+1, j+1] <= 1)
        end
    end

    for i in 1:n+2
        @constraint(m, X[i, 1] == 0)
        @constraint(m, X[i, p+2] == 0)
    end
    for j in 1:p+2
        @constraint(m, X[1, j] == 0)
        @constraint(m, X[n+2, j] == 0)
    end

    #domino :
    @constraint(m, sum(dom_h[i,j] for i in 1:n, j in 1:p) + sum(dom_v[i,j] for i in 1:n, j in 1:p) == sum(A))
    for i in 1:n
        @constraint(m, dom_h[i, p] == 0) 
    end
    for j in 1:p
        @constraint(m, dom_v[n, j] == 0) 
    end

    #non-superposition pour les dominos horizontaux
    for i in 2:n
        for j in 1:p-1
            @constraint(m, dom_h[i, j] + dom_h[i, j+1] <= 1)
            @constraint(m, dom_h[i, j] + dom_v[i-1, j+1] <= 1)
            @constraint(m, dom_h[i, j] + dom_v[i-1, j] <= 1)
            @constraint(m, dom_h[i, j] + dom_v[i, j+1] <= 1)
            @constraint(m, dom_h[i, j] + dom_v[i, j] <= 1)
        end
    end
    for j in 1:p-1
        @constraint(m, dom_h[1, j] + dom_h[1, j+1] <= 1)
    end


    #non-superposition pour les dominos verticaux
    for i in 1:n-1
        for j in 1:p
            @constraint(m, dom_v[i, j] + dom_v[i+1, j] <= 1)
        end
    end

    # association tente arbre
    for i in 1:n
        for j in 1:p-1
            @constraint(m, X[i+1,j+1] + X[i+1,j+2] - 2*quotient_X_h[i,j] >= 0)
            @constraint(m, X[i+1,j+1] + X[i+1,j+2] - 2*quotient_X_h[i,j] <= 1)
            @constraint(m, X_et_droite[i,j] == X[i+1,j+1] + X[i+1,j+2] - 2*quotient_X_h[i,j])

            @constraint(m, A[i,j] + A[i,j+1] - 2*quotient_A_h[i,j] >= 0)
            @constraint(m, A[i,j] + A[i,j+1] - 2*quotient_A_h[i,j] <= 1)
            @constraint(m, A_et_droite[i,j] == A[i,j] + A[i,j+1] - 2*quotient_A_h[i,j])

            @constraint(m, dom_h_aux[i, j] <= 2 - A_et_droite[i,j] - X_et_droite[i,j]  )
            @constraint(m, dom_h_aux[i,j] + dom_h[i,j]<= 1) 
            
        end
    end
    for i in 1:n-1
        for j in 1:p

            @constraint(m, X[i+1,j+1] + X[i+2,j+1] - 2*quotient_X_v[i,j] >= 0)
            @constraint(m, X[i+1,j+1] + X[i+2,j+1] - 2*quotient_X_v[i,j] <= 1)
            @constraint(m, X_et_bas[i,j] == X[i+1,j+1] + X[i+2,j+1] - 2*quotient_X_v[i,j])

            @constraint(m, A[i,j] + A[i+1,j] - 2*quotient_A_v[i,j] >= 0)
            @constraint(m, A[i,j] + A[i+1,j] - 2*quotient_A_v[i,j] <= 1)
            @constraint(m, A_et_bas[i,j] == A[i,j] + A[i+1,j] - 2*quotient_A_v[i,j])

            @constraint(m, dom_v_aux[i, j] <= 2 - A_et_bas[i,j] - X_et_bas[i,j])
            @constraint(m, dom_v_aux[i,j] + dom_v[i,j]<= 1) 
        end
    end

    @objective(m, Min, 1)
   
    start = time()

    # Solve the model
    optimize!(m)
    solFound = primal_status(m) == MOI.FEASIBLE_POINT
    println("SOLUTION TROUVEE ? ", solFound)
    if solFound
        vX = JuMP.value.(X)
        println("SOLUTION : ")
        displaySolution(vX)
        return solFound, time() - start, vX
    end
    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return solFound, time() - start, 0
    
end

"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
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
    resolutionMethod = ["cplex"]
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
end

solveDataSet()

