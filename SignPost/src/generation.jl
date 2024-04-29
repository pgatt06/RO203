# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")
using Random

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

    #si on veut forcer le départ du chemin à la première case
    Chemin=[1]

    #si on veut commencer par un point aléatoire
    #Chemin=Int64[rand(1:n^2)]
    #def du chemin initial
    Chemin_0=Chemin

    #on remplit le chemin jusqu'à ce qu'il soit de taille n^2
    while length(Chemin) < n^2
        # Trouver tous les sommets accessibles qui sont adjacents au dernier sommet du chemin
        sommet_pas_chemin=filter(s->!(s in Chemin),[j for j in 1:n^2])
        sommet_accessibles=filter(s->ConditionsFleches[Chemin[end],s]==1,sommet_pas_chemin)
        
        if isempty(sommet_accessibles) #si on est bloqués on recommence à 0
            Chemin=Chemin_0
        else
        # Choisir aléatoirement un sommet accessible qui est adjacent au dernier sommet du chemin
        sommet_suivant = rand(sommet_accessibles)
         # Ajouter le sommet choisi au chemin
        push!(Chemin, sommet_suivant)
        end
    end
    #on retourne la liste des cases dans l'ordre du chemin 
    return Chemin
end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generate_MatricesFlèches(n::Int64)
    
    #la chaine solution du pb celle qui faut trouver 
    chaine = generateCheminHamiltonien(n)

    #matrice avec les chiffres indiquant les flèches du jeu
    Jeu = Matrix{Int64}(undef,n,n)

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

    #cette condition permet de bloquer la derniere case en tant que case finale 
    #matrice de contraintes
    Contrainte = Matrix{Int64}(0,n,n)
    
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

    #on remplit la matrice de contraintes de façon aléatoire 
    k=Int64(rand(0:n^2/2))
    while k>0
        #on tire une case au hasard
        i= Int64(rand(1:n^2))
        case_pos_i =Chemin[i]
        ligne = (case_pos_i-1)÷n+1
        col = (case_pos_i-1)%n+1
        #on impose que cette case soit en position i dans le chemin
        Contrainte[ligne,col]= i
    end
return jeu, Contrainte
end


function generateDataSet()
    n=Int64(rand(3:7))
    Jeu,Contraintes =generate_MatricesFlèches(n)

    fichier = open(InstanceTest2.txt, "w")
    write(fichier, string(n))
    write(fichier, "\n")
    writecsv(fichier, Jeu)
    write(fichier, "\n")
    writecsv(fichier, Contraintes)
    close(fichier)
end
