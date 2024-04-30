# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using JuMP
using MathOptInterface



include("generation.jl")
include("io.jl")
include("arbre.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(A,Chemins_possibles,Contraintes_jeux)

    # Create the model
    m = Model(CPLEX.Optimizer)

    ##la taille du tableau 
    n=size(A,1)

    #La matrice de Chemin 
    @variable(m,C[1:n^2,1:n^2],Bin)

    ##les contraintes 

    #il ne faut qu'un seul successeur
    for i in 1:n^2
        @constraint(m,sum(C[i,j] for j in 1:n^2)==1)
    end

    #il ne faut qu'un seul prédécesseur
    for j in 1:n^2
        @constraint(m,sum(C[i,j] for i in 1:n^2)==1)
    end

    #il ne faut passer que par des chemins existants
    for k in 1:n*n-1
        for i in 1:n^2
            for j in 1:n^2
                @constraint(m,C[i,k]*C[j,k+1]<=Chemins_possibles[i,j])
            end
        end
    end

    #contrainte de passer par les cases imposées 

    for i in 1:n
        for j in 1:n
            #si on a 0 il n'y a pas de contrainte sinon il y en a une 
            if Contraintes_jeux[i,j] != 0
                @constraint(m, C[(i-1)*n + j , Contraintes_jeux[i,j]]==1)
            end
        end
    end

    #fonction objective constante car on ne cherche à savoir que si il existe une solution
    @objective(m,Min,1)
    # Start a chronometer
    start = time()

    # Solve the model
    sol=optimize!(m)

    #on retourne le chemin solution 
    Matrice_Chemin_solution = value.(C)

    Chemin_solution=Vector{Int64}(undef,n^2)
    for i in 1:n^2
        for j in 1:n^2
            if Matrice_Chemin_solution[i,j]==1
                Chemin_solution[i]=j
            end
        end
    end

    println("le chemin solution est :", Chemin_solution)
    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == MathOptInterface.FEASIBLE_POINT, time() - start, Chemin_solution
    
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

    # Create each result folder for each resolution method if it does not exist
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
        println("-- Resolution of ", file)
        readInputFile(dataFolder * file)

        #récupération des données 
        A,Chemins_possibles,Contraintes_jeux=readInputFile("data/instanceTest.txt")
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime, solution = cplexSolve(A,Chemins_possibles,Contraintes_jeux)
                    
                    print(isOptimal)
                    print(resolutionTime)
                    # If a solution is found, write it
                    if isOptimal

                        println(fout,"solution = ", solution)

                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
