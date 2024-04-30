# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")
using Random

using CPLEX
using JuMP
using MathOptInterface

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
#fonction qui permet de générer un chemin hamiltonien aléatoirement dans le quadrillage 
#condition respecter les déplacements possibles
function colonne_id(i::Int64,j::Int64, n::Int64)
    return (i%n==j%n)
end

function ligne_id(i::Int64, j::Int64, n::Int64)
    return i÷n==j÷n
end

#même diagonale ie difference ligne colonne =0
function diagonale_id(i::Int64, j::Int64, n::Int64)
    return (i%n-j%n) == (i÷n-j÷n)
end


function generateCheminHamiltonien(n::Int64)
    #matrice de 1 et de 0 indiquant les chemins possibles selon leur positions 
    #on peut aller sur la même ligne ou colonne ou diagonnale
    ConditionsFleches = Matrix{Int64}(undef,n^2,n^2)

    for i in 1:n^2
        for j in 1:n^2
            if colonne_id(i,j,n) || ligne_id(i,j,n) || diagonale_id(i,j,n)
                ConditionsFleches[i,j] = 1
            else
                ConditionsFleches[i,j] = 0
            end
        end
    end


    m = Model(CPLEX.Optimizer)

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
                @constraint(m,C[i,k]*C[j,k+1]<=ConditionsFleches[i,j])
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

    return Chemin_solution
end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generate_MatricesFlèches(n::Int64,contraintes::Bool=false)
    
    #la chaine solution du pb celle qui faut trouver 
    chaine = generateCheminHamiltonien(n)
    if length(chaine)<n^2
        println("pas de solution")
        return
    end

    #print(chaine)

    #matrice avec les chiffres indiquant les flèches du jeu
    jeu = Matrix{Int64}(undef,n,n)

    #on remplit la matrice jeu avec les flèches correspondant à la chaine solution
    for k in 1:(n^2-1)

        point = chaine[k]
        suivant = chaine[k+1]

        #i correspond à la ligne et j à la colonne dans le quadrillage
        i = (point-1)÷n+1
        j = (point-1)%n+1
        
        i_suivant = (suivant-1)÷n+1
        j_suivant = (suivant-1)%n+1

        #on regarde sur la même colonne et si au dessus/dessous
        if j_suivant == j
            if i_suivant < i
                jeu[i,j] = 0 #haut
            else 
                jeu[i,j] = 4 # bas 
            end

        #on regarde sur la même ligne et si à gauche/droite

        elseif i_suivant == i 
            if j_suivant < j 
                jeu[i,j] = 6 # gauche
            else 
                jeu[i,j] = 2 # droite
            end 

        #on regarde sur les diagonales 
        #on regarde en haut ie i_suivant< i
        #haut et gauche
        elseif i_suivant < i 
            if j_suivant < j 
                jeu[i,j] = 7 
            else 
                #haut et droite 
                jeu[i,j] = 1 
            end

        #on regarde en bas ie i_suivant
        elseif i_suivant > i
            #en bas à gauche
            if j_suivant < j 
                jeu[i,j] = 5 
            else
            #en bas à droite 
                jeu[i,j] = 3
            end
        end
    end

    fin= chaine[end] 

    i_f = (fin-1)÷n+1
    j_f = (fin-1)%n+1

    #la fin 10 nombre non attribuer pour les flèches
    jeu[i_f,j_f]=10
    #cette condition permet de bloquer la derniere case en tant que case finale 
    #matrice de contraintes
    Contrainte = Matrix{Int64}(undef,n,n)

    for i in 1:n
        for j in 1:n
            Contrainte[i,j]=0
        end
    end
    
    debut=chaine[1]
    fin=chaine[end]

    #on impose le début et la fin 

    i_d = (debut-1)÷n+1
    j_d = (debut-1)%n+1

    i_f = (fin-1)÷n+1
    j_f = (fin-1)%n+1

    Contrainte[i_d,j_d]=1
    Contrainte[i_f,j_f]=n^2
    #Si on veut des contraintes en plus permet de s'assurer que la solution est unique
    if contraintes
        #on remplit la matrice de contraintes de façon aléatoire 
        k=Int64(rand(0:n^2/2))
        while k>0
            #on tire une case au hasard
            i= Int64(rand(1:n^2))
            case_pos_i =chaine[i]
            ligne = (case_pos_i-1)÷n+1
            col = (case_pos_i-1)%n+1
            #on impose que cette case soit en position i dans le chemin
            Contrainte[ligne,col]= i
        end
    end
return jeu, Contrainte
end


function generateDataSet(n::Int64,nb_dataSet::Int64,contraintessup::Bool=false)

    for h in 1:nb_dataSet
        filename="data//instanceText_$h.txt"
        io = open(filename, "w")  # Ouvre le fichier en mode écriture
        jeu,Contraintes =generate_MatricesFlèches(n,contraintessup)
        write(io,string(n))
        write(io,"\n")
        for i in 1:n
            for j in 1:n-1
                write(io, string(jeu[i, j]))  # Écrit l'élément de la matrice dans le fichier
                write(io, ",")  # Ajoute une virgule entre chaque élément sauf le dernier
            end
            write(io, string(jeu[i, n]))
            write(io,"\n")
        end
        
        write(io,"\n")

        for i in 1:n
            for j in 1:n-1
                write(io, string(Contraintes[i, j]))  # Écrit l'élément de la matrice dans le fichier
                write(io, ",")  # Ajoute une virgule entre chaque élément sauf le dernier
            end
            write(io, string(Contraintes[i, n]))
            write(io,"\n")
        end   
        close(io)
    end
end

