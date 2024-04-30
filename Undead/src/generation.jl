# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64)
    jeu=Matrix{Int64}(undef,n,n)
    for h in 1:n
        for k in 1:n
            jeu[h,k]=rand(1:5)
        end
    end
    # 1/ 2\ 3g 4v 5z
    #println(jeu) 
    g= count(x -> x == 3, jeu)
    v= count(x -> x == 4, jeu)
    z= count(x -> x == 5, jeu)
    list_left=[0 for i in 1:n]
    list_right=[0 for i in 1:n]
    for i in 1:n #gauche
        ligne=i
        colonne=1
        first_mir=0
        rigth=1
        up=0
        #print(i)
        #print(":\n")
        while ligne>0 && ligne <n+1 && colonne>0 && colonne<n+1
            
            if jeu[ligne,colonne]==5
                list_left[i]+=1
            end
            if (jeu[ligne,colonne]==4 ) && first_mir==0
                list_left[i]+=1
            end
            if (jeu[ligne,colonne]==3 ) && first_mir==1
                list_left[i]+=1
            end
            #print(ligne)
            #print(",")
            #print(colonne)
            #print("\n")
            if jeu[ligne,colonne]==1
                first_mir=1 
                if up==0
                    up=-rigth
                    rigth=0
                else
                    rigth=-up
                    up=0
                end
            end
            if jeu[ligne,colonne]==2
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

        ligne=i
        colonne=n
        first_mir=0
        rigth=-1
        up=0
        while ligne>0 && ligne <n+1 && colonne>0 && colonne<n+1
            if jeu[ligne,colonne]==5
                list_right[i]+=1
            end
            if (jeu[ligne,colonne]==4 ) && first_mir==0
                list_right[i]+=1
            end
            if (jeu[ligne,colonne]==3 ) && first_mir==1
                list_right[i]+=1
            end
            if jeu[ligne,colonne]==1 
                first_mir=1
                if up==0
                    up=-rigth
                    rigth=0
                else
                    rigth=-up
                    up=0
                end
            end
            if jeu[ligne,colonne]==2 
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
    list_top=[0 for i in 1:n]
    list_bottom=[0 for i in 1:n]
    for i in 1:n #gauche                
        ligne=1
        colonne=i
        first_mir=0
        rigth=0
        up=1
        while ligne>0 && ligne <n+1 && colonne>0 && colonne<n+1
            if jeu[ligne,colonne]==5
                list_top[i]+=1
            end
            if (jeu[ligne,colonne]==4 ) && first_mir==0
                list_top[i]+=1
            end
            if (jeu[ligne,colonne]==3 ) && first_mir==1
                list_top[i]+=1
            end
            if jeu[ligne,colonne]==1 
                first_mir=1
                if up==0
                    up=-rigth
                    rigth=0
                else
                    rigth=-up
                    up=0
                end
            end
            if jeu[ligne,colonne]==2 
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
        while ligne>0 && ligne <n+1 && colonne>0 && colonne<n+1
            if jeu[ligne,colonne]==5
                list_bottom[i]+=1
            end
            if (jeu[ligne,colonne]==4)&& first_mir==0
                list_bottom[i]+=1
            end
            if (jeu[ligne,colonne]==3 ) && first_mir==1
                list_bottom[i]+=1
            end
            if jeu[ligne,colonne]==1 
                first_mir=1
                if up==0
                    up=-rigth
                    rigth=0
                else
                    rigth=-up
                    up=0
                end
            end
            if jeu[ligne,colonne]==2 
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
    
    #for i in 1:n
    #    for j in 1:n
     #       if jeu[i,j]==1
       #         print("/,")
      #      
        #    elseif jeu[i,j]==2
         #       print("\\,")
            #
          ##  else
             #   print(jeu[i,j])
              #  print(",")
           # end
        #end
       ## print("\n")
    #end
    #println("ohé")
    #println(list_bottom)*
    filename="../solution/instanceText_$n.txt"
    io = open(filename, "w")
    for i in 1:n
        write(io,",")
        for j in 1:n
            if jeu[i,j]==1
                write(io, "/,")
            
            end
            if jeu[i,j]==2
                write(io, "\\,")
                
            end
            if jeu[i,j]==3
                write(io,"G,")
            end
            if jeu[i,j]==4
                write(io,"V,")
            end
            if jeu[i,j]==5
                write(io,"Z,")
            end
        end
        write(io,"\n")
        
    end
    close(io)

    for i in 1:n
        for j in 1:n
            if jeu[i,j]!=1 && jeu[i,j]!=2
                jeu[i,j]=0
            end
        end
    end

    


    
    return g,v,z,n,n,jeu,list_bottom,list_left,list_top,list_right
    
end 

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet(n::Int64,nb_dataSet::Int64)

    for h in 1:nb_dataSet
        filename="../data/instanceText_$h.txt"
        io = open(filename, "w")
        g,v,z,nn,k,jeu,list_bottom,list_left,list_top,list_right=generateInstance(h)
        write(io,string(g))
        write(io,",")
        write(io,string(v))
        write(io,",")
        write(io,string(z))
        write(io,",")
        write(io,string(h))
        write(io,",")
        write(io,string(h))
        write(io,"\n")
        for i in 1:nn
            write(io, string(list_top[i]))
            if i<nn
                write(io, ",")  # Ajoute une virgule entre chaque élément sauf le dernier
            end
        end
        write(io,"\n")
        for i in 1:nn
            write(io,string(list_left[i]))
            write(io,",")
            for j in 1:nn
                if jeu[i,j]==1
                    write(io, "/,")
                
                end
                if jeu[i,j]==2
                    write(io, "\\,")
                    
                end
                if jeu[i,j]==0
                    write(io,"0,")
                    
                end
            end
            write(io,string(list_right[i]))
            write(io,"\n")
            
        end
        for i in 1:nn
            write(io, string(list_bottom[i]))
            if i<nn
                write(io, ",")  # Ajoute une virgule entre chaque élément sauf le dernier
            end
        end
        close(io)
    end

    
end



