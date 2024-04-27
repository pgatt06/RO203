# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""


function ligne_id(pt1::Int64, pt2::Int64, n::Int64)
    return pt1÷n==pt2÷n
end
    
function colonne_id(pt1::Int64, pt2::Int64, n::Int64)
    return pt1%n==pt2%n
end

function diag_id

function generateInstance(n::Int64, density::Float64)

    chaine=[1]
    pas_prendre=[[]for k in 1:n^2]
    

end 

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generate_Matrices(n::Int64)
    
    #la chaine solution du pb celle qui faut trouver 
    chaine = generateInstance(n)

    #matrice avec les chiffres indiquant les flèches du jeu
    Jeu = Matrix{Int64}(undef,n,n)

    #on remplit la matrice jeu avec les flèches correspondant à la chaine solution
    for k in 1:(n*n-1)

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

    #cette condition permet de bloquer la derniere case en tant que case finale 
    jeu[n,n] = 7 

    #matrice de contraintes
    Contrainte = Matrix{Int64}(0,n,n)
    Contrainte[1,1]=1
    Contrainte[n,n]=n^2

    #on remplit la matrice de contraintes   




return n,jeu, Contrainte
end


function generateDataSet()
    n=rand((3, 6))

end