# This file contains methods to generate a data set of instances (i.e., sudoku grids)

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""



function generateInstance(n::Int64, density::Float64)
    prendre=[[1*(rand(1:100)<density*100) for h in 1:n] for k in 1:n]
    return prendre

end 

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does ! already exist
"""
function check_around(i,j,matrice,n)
    haut = i > 1
    bas = i < n
    gauche = j > 1
    droite = j < n
    
    # Vérification des cases adjacentes
    haut_gauche = haut && gauche && matrice[i-1, j-1] == 2
    haut_droite = haut && droite && matrice[i-1, j+1] == 2
    bas_gauche = bas && gauche && matrice[i+1, j-1] == 2
    bas_droite = bas && droite && matrice[i+1, j+1] == 2
    haut_centre = haut && matrice[i-1, j] == 2
    bas_centre = bas && matrice[i+1, j] == 2
    gauche_centre = gauche && matrice[i, j-1] == 2
    droite_centre = droite && matrice[i, j+1] == 2
    
    # Vérification de la présence de 2 autour de (i, j) même en diagonale
    return haut_gauche || haut_droite || bas_gauche || bas_droite || haut_centre || bas_centre || gauche_centre || droite_centre
end

function generate_Matrices(n::Int64,density::Float64=0.2)
    
    #la chaine solution du pb celle qui faut trouver 
    loc_arbre = generateInstance(n,density)

    #matrice avec les chiffres indiquant les flèches du jeu
    Jeu = Matrix{Int64}(undef,n,n)
    for k in 1:n
        for h in 1:n
            Jeu[k,h]=0
        end
    end

    #on remplit la matrice jeu avec les flèches correspondant à la chaine solution
    #println(loc_arbre)
    for k in 1:n
        for h in 1:n
            dir_pos=[1,2,3,4]
            i=4
            while loc_arbre[k][h]==1 && i!=0
                obj=rand(1:i)
                i-=1
                dir=dir_pos[obj]
                deleteat!(dir_pos, obj)
                #print(dir)
                if dir==1
                    if h+1<n && Jeu[k,h+1]==0
                        if !(check_around(k,h+1,Jeu,n))
                            Jeu[k,h+1]=2
                            Jeu[k,h]=1
                            loc_arbre[k][h]=0
                        end
                    end
                end
                if dir==2
                    if k+1<n && Jeu[k+1,h]==0
                        if !(check_around(k+1,h,Jeu,n))
                            Jeu[k+1,h]=2
                            Jeu[k,h]=1
                            loc_arbre[k][h]=0
                        end
                    end
                end
                if dir==3
                    if h-1>1 && Jeu[k,h-1]==0
                        if !(check_around(k,h-1,Jeu,n))
                            Jeu[k,h-1]=2
                            Jeu[k,h]=1
                            loc_arbre[k][h]=0
                        end
                    end
                end
                if dir==4
                    if k-1>1 && Jeu[k-1,h]==0
                        if !(check_around(k-1,h,Jeu,n))
                            Jeu[k-1,h]=2
                            Jeu[k,h]=1
                            loc_arbre[k][h]=0
                        end
                    end
                end
            end
        end
    end
    #cette condition permet de bloquer la derniere case en tant que case finale 
    for k in 1:n
        for h in 1:n
            print(Jeu[k,h])
        end
        print("\n")
    end

    
    count_rows = zeros(Int, n)
    count_cols = zeros(Int, n)
    
    for i in 1:n
        count_rows[i] = count(x -> x == 2, Jeu[i, :])
    end
    
    for j in 1:n
        count_cols[j] = count(x -> x == 2, Jeu[:, j])
    end

    for k in 1:n
        for h in 1:n
            if Jeu[k,h]==2
                Jeu[k,h]=0
            end
        end
    end
    #on remplit la matrice de contraintes   
    return n,Jeu,count_rows,count_cols
end


function generateDataSet(n::Int64,nb_dataSet::Int64,density::Float64=0.2)

    for h in 1:nb_dataSet
        filename="data//instanceText_$h.txt"
        io = open(filename, "w")  # Ouvre le fichier en mode écriture
        n,jeu,count_rows,count_cols=generate_Matrices(n,density)
        write(io,string(n))
        write(io,"\n")
        for i in 1:n
            for j in 1:n
                write(io, string(jeu[i, j]))  # Écrit l'élément de la matrice dans le fichier
                write(io, ",")  # Ajoute une virgule entre chaque élément sauf le dernier
            end
            write(io, string(count_rows[i]))
            
            write(io, "\n")  # Ajoute un retour à la ligne après chaque ligne sauf la dernière
            
        end
        for i in 1:n
            write(io, string(count_cols[i]))
            if i<n
                write(io, ",")  # Ajoute une virgule entre chaque élément sauf le dernier
            end
        end
        close(io)
    end
end