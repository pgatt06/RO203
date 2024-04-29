include("src/io.jl")

function trouver_chemin(A,Chemins_possibles, contraintes)
    n = size(A, 1)
    chemin = [1]  # Commencer par le premier sommet
    #liste des sommets visités
    sommets_visites = [1]
    
    function tt_parcouru(sommet)
        #si toutes les cases sont dans le chemin
        if length(chemin) == n^2
            return true  # Tous les sommets ont été visités
        end
        
        for voisin in 1:n^2
            if Chemins_possibles[sommet, voisin]==1 && !(voisin in sommets_visites) &&( contraintes[voisin] == length(chemin) + 1 || contraintes[voisin] == 0)
                push!(chemin, voisin)
                push!(sommets_visites, voisin)
                
                if tt_parcouru(voisin)
                    return true
                end
                
                pop!(chemin)
                pop!(sommets_visites)
            end
        end
        
        return false
    end
    
    if tt_parcouru(1)
        return chemin
    else
        return []
    end
end

A,B,C=readInputFile("data/instanceTest.txt")
chemin=trouver_chemin(A,B,C)
println(chemin)