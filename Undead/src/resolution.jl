# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using MathOptInterface 

include("generation.jl")
include("io.jl")

TOL = 0.00001


function cplexSolve(input::String)

    # Create the model
    
    m = Model(CPLEX.Optimizer)
    
    g,v,z,n,k,tableau,list_bottom,list_left,list_top,list_right=readInputFile(input)
    #println(tableau[1,2])
    #println(k)
    #println(n)
    #println(list_right)
    #println(list_bottom)
    start = time()
    direct_value= zeros(Int, n, k,2*k+2*n)
    indirect_value=zeros(Int, n, k,2*k+2*n)
    
    for i in 1:k #gauche
        realline=i
        ligne=i
        colonne=1
        first_mir=0
        rigth=1
        up=0
        while ligne>0 && ligne <n+1 && colonne>0 && colonne<k+1
            
            
            if tableau[ligne,colonne]==0 && first_mir==0
                direct_value[ligne,colonne,realline]+=1
            end
            if tableau[ligne,colonne]==0 && first_mir==1
                indirect_value[ligne,colonne,realline]+=1
            end
            if tableau[ligne,colonne]==1
                first_mir=1 
                if up==0
                    up=-rigth
                    rigth=0
                else
                    rigth=-up
                    up=0
                end
            end
            if tableau[ligne,colonne]==2
                first_mir=1
                if up==0
                    up=rigth
                    rigth=0
                else
                    rigth=up
                    up=0
                end
            end
            colonne+=rigth
            ligne+=up
        
        end

        realline=i
        colonne=k
        ligne=i
        first_mir=0
        rigth=-1
        up=0
        while ligne>0 && ligne <n+1 && colonne>0 && colonne<k+1
            if tableau[ligne,colonne]==0 && first_mir==0
                direct_value[ligne,colonne,k+realline]+=1
            end
            if tableau[ligne,colonne]==0 && first_mir==1
                indirect_value[ligne,colonne,k+realline]+=1
            end
            if tableau[ligne,colonne]==1 
                first_mir=1
                if up==0
                    up=-rigth
                    rigth=0
                else
                    rigth=-up
                    up=0
                end
            end
            if tableau[ligne,colonne]==2 
                first_mir=1
                if up==0
                    up=rigth
                    rigth=0
                else
                    rigth=up
                    up=0
                end

            end
            colonne+=rigth
            ligne+=up
        
        end
    end 
    #println(tableau)
    for i in 1:n #gauche                
        ligne=1
        colonne=i
        first_mir=0
        rigth=0
        up=1
        while ligne>0 && ligne <n+1 && colonne>0 && colonne<k+1
            
            if tableau[ligne,colonne]==0 && first_mir==0
                direct_value[ligne,colonne,2*k+i]+=1
            end
            if tableau[ligne,colonne]==0 && first_mir==1
                indirect_value[ligne,colonne,2*k+i]+=1
            end
            if tableau[ligne,colonne]==1 
                first_mir=1
                if up==0
                    up=-rigth
                    rigth=0
                else
                    rigth=-up
                    up=0
                end
            end
            if tableau[ligne,colonne]==2 
                first_mir=1
                if up==0
                    up=rigth
                    rigth=0
                else
                    rigth=up
                    up=0
                end



            end
            ligne+=up
            colonne+=rigth
        
        
        end

        ligne=n
        colonne=i
        first_mir=0
        rigth=0
        up=-1
        while ligne>0 && ligne <n+1 && colonne>0 && colonne<k+1
            if tableau[ligne,colonne]==0 && first_mir==0
                direct_value[ligne,colonne,2*k+n+i]+=1
            end
            if tableau[ligne,colonne]==0 && first_mir==1
                indirect_value[ligne,colonne,2*k+n+i]+=1
            end
            if tableau[ligne,colonne]==1 
                first_mir=1
                if up==0
                    up=-rigth
                    rigth=0
                else
                    rigth=-up
                    up=0
                end
            end
            if tableau[ligne,colonne]==2 
                first_mir=1
                if up==0
                    up=rigth
                    rigth=0
                else
                    rigth=up
                    up=0
                end



            end
            ligne+=up
            colonne+=rigth
        
        end
            
    
    end

    

    # Start a chronometer
    #println(direct_value)
    #println(indirect_value)


    
    @variable(m, g_l[1:n,1:k] >= 0, Int)
    @variable(m, z_l[1:n,1:k] >= 0, Int)
    @variable(m, v_l[1:n,1:k] >= 0, Int)
    # Solve the model
    for i in 1:n
        for j in 1:k
            @constraint(m,g_l[i,j]+z_l[i,j]+v_l[i,j]<=1)
            if tableau[i,j] !=0
                @constraint(m,g_l[i,j]==0)
                @constraint(m,z_l[i,j]==0)
                @constraint(m,v_l[i,j]==0)
            end
        end
    end
    @constraint(m,sum(sum(v_l[i,j] for i in 1:n) for j in 1:k)==v)
    @constraint(m,sum(sum(z_l[i,j] for i in 1:n) for j in 1:k)==z)
    @constraint(m,sum(sum(g_l[i,j] for i in 1:n) for j in 1:k)==g)
    h=1
    for elt in list_left
    @constraint(m,sum(sum(direct_value[i,j,h]*(z_l[i,j]+ v_l[i,j])+indirect_value[i,j,h]*(g_l[i,j]+ z_l[i,j]) for i in 1:n) for j in 1:k)==elt)
    h+=1
    end
    for elt in list_right
        @constraint(m,sum(sum(direct_value[i,j,h]*(z_l[i,j]+ v_l[i,j])+indirect_value[i,j,h]*(g_l[i,j]+ z_l[i,j]) for i in 1:n) for j in 1:k)==elt)
        h+=1
    end
    for elt in list_top
        @constraint(m,sum(sum(direct_value[i,j,h]*(z_l[i,j]+ v_l[i,j])+indirect_value[i,j,h]*(g_l[i,j]+ z_l[i,j]) for i in 1:n) for j in 1:k)==elt)
        h+=1
    end
    for elt in list_bottom
        @constraint(m,sum(sum(direct_value[i,j,h]*(z_l[i,j]+ v_l[i,j])+indirect_value[i,j,h]*(g_l[i,j]+ z_l[i,j]) for i in 1:n) for j in 1:k)==elt)
        h+=1
    end
    optimize!(m)
    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    isOptimal = termination_status(m) == MOI.OPTIMAL
    solutionFound = primal_status(m) == MOI.FEASIBLE_POINT
    if solutionFound
        vZ = JuMP.value.(z_l[1:n,1:k])
        println(vZ)
        vG = JuMP.value.(g_l[1:n,1:k])
        println(vG)
        vV = JuMP.value.(v_l[1:n,1:k])
        println(vV)
        return JuMP.primal_status(m) == JuMP.MOI.FEASIBLE_POINT, time() - start, vZ,vG,vV
        
    end
    return JuMP.primal_status(m) == JuMP.MOI.FEASIBLE_POINT, time() - start,zeros(Int64,n,k),zeros(Int64,n,k),zeros(Int64,n,k)
    
end

"""
Heuristically solve an instance
"""
function heuristicSolve()
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input && output, define the model")

    g,v,z,n,k,tableau,list_bottom,list_left,list_top,list_right=readInputFile("../data/InstanceTest.txt")
    #println(tableau[1,2])
    #println(k)
    #println(n)
    #println(list_right)
    #println(list_bottom)
    direct_value= zeros(Int, n, k,2*k+2*n)
    indirect_value=zeros(Int, n, k,2*k+2*n)
    
    for i in 1:k #gauche
        realline=i
        ligne=1
        colonne=i
        first_mir=0
        rigth=1
        up=0
        while ligne>0 && ligne <n+1 && colonne>0 && colonne<k+1
            
            
            if tableau[colonne,ligne]==0 && first_mir==0
                direct_value[colonne,ligne,realline]+=1
            end
            if tableau[colonne,ligne]==0 && first_mir==1
                indirect_value[colonne,ligne,realline]+=1
            end
            if tableau[colonne,ligne]==1
                first_mir=1 
                if up==0
                    up=-rigth
                    rigth=0
                else
                    rigth=-up
                    up=0
                end
            end
            if tableau[colonne,ligne]==2
                first_mir=1
                if up==0
                    up=rigth
                    rigth=0
                else
                    rigth=up
                    up=0
                end
            end
            ligne+=rigth
            colonne+=up
        
        end

        realline=i
        ligne=k
        colonne=i
        first_mir=0
        rigth=-1
        up=0
        while ligne>0 && ligne <n+1 && colonne>0 && colonne<k+1
            if tableau[colonne,ligne]==0 && first_mir==0
                direct_value[colonne,ligne,k+realline]+=1
            end
            if tableau[colonne,ligne]==0 && first_mir==1
                indirect_value[colonne,ligne,k+realline]+=1
            end
            if tableau[colonne,ligne]==1 
                first_mir=1
                if up==0
                    up=-rigth
                    rigth=0
                else
                    rigth=-up
                    up=0
                end
            end
            if tableau[colonne,ligne]==2 
                first_mir=1
                if up==0
                    up=rigth
                    rigth=0
                else
                    rigth=up
                    up=0
                end

            end
            ligne+=rigth
            colonne+=up
        
        end
    end 
    println(tableau)
    for i in 1:n #gauche                
        ligne=1
        colonne=i
        first_mir=0
        rigth=0
        up=1
        while ligne>0 && ligne <n+1 && colonne>0 && colonne<k+1
            if i==2
                println(ligne)
                println(colonne)
                println(tableau[ligne,colonne])
            end
            if tableau[ligne,colonne]==0 && first_mir==0
                direct_value[ligne,colonne,2*k+i]+=1
            end
            if tableau[ligne,colonne]==0 && first_mir==1
                indirect_value[ligne,colonne,2*k+i]+=1
            end
            if tableau[ligne,colonne]==1 
                first_mir=1
                if up==0
                    up=-rigth
                    rigth=0
                else
                    rigth=-up
                    up=0
                end
            end
            if tableau[ligne,colonne]==2 
                first_mir=1
                if up==0
                    up=rigth
                    rigth=0
                else
                    rigth=up
                    up=0
                end



            end
            ligne+=up
            colonne+=rigth
        
        
        end

        ligne=n
        colonne=i
        first_mir=0
        rigth=0
        up=-1
        while ligne>0 && ligne <n+1 && colonne>0 && colonne<k+1
            if tableau[ligne,colonne]==0 && first_mir==0
                direct_value[ligne,colonne,2*k+n+i]+=1
            end
            if tableau[ligne,colonne]==0 && first_mir==1
                indirect_value[ligne,colonne,2*k+n+i]+=1
            end
            if tableau[ligne,colonne]==1 
                first_mir=1
                if up==0
                    up=-rigth
                    rigth=0
                else
                    rigth=-up
                    up=0
                end
            end
            if tableau[ligne,colonne]==2 
                first_mir=1
                if up==0
                    up=rigth
                    rigth=0
                else
                    rigth=up
                    up=0
                end



            end
            ligne+=up
            colonne+=rigth
        
        end
            
    
    end

    

    # Start a chronometer
    println(direct_value)
    println(indirect_value)

    zombie_possible= zeros(Int, n, k)
    ghost_possible =zeros(Int, n, k)
    vampire_possible =zeros(Int, n, k)

    ##1 si possible, 0 si impossible, 2 si certain
    concat=vcat(list_left,list_right,list_top,list_bottom)
    score_obj=vec(concat)


    
    
    
end 

"""
Solve all the instances contained in "../data" through CPLEX && heuristics

The results are written in "../res/cplex" && "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

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
        
        println("-- Resolution of ", file)
        #readInputFile(dataFolder * file)
        
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
                    
                    # Solve it && get the results
                    isOptimal, resolutionTime,vZ,vG,vV = cplexSolve(dataFolder * file)
                    println(isOptimal)
                    # If a solution is found, write it
                    if isOptimal
                        write(fout,"\nZombie:\n")
                        n,k=size(vZ)
                        for i in 1:n
                            for j in 1:k
                                write(fout,string(vZ[i,j]))
                                write(fout,",")
                            end
                            write(fout,"\n")
                        end
                        write(fout,"Ghost:\n")
                        for i in 1:n
                            for j in 1:k
                                write(fout,string(vG[i,j]))
                                write(fout,",")
                            end
                            write(fout,"\n")
                        end
                        write(fout,"Vampire:\n")
                        for i in 1:n
                            for j in 1:k
                                write(fout,string(vV[i,j]))
                                write(fout,",")
                            end
                            write(fout,"\n")
                        end
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved && less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments && returned values")
                        
                        # Solve it && get the results
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
            #include(outputFile)
            #println(resolutionMethod[methodId], " optimal: ", isOptimal)
            #println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
