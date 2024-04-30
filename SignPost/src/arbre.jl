struct NewTreeNode
    case::Int
    pred::Vector{Int}
end



function True_succ(pred::Vector{Int},noeud::Int,succ_list::Vector{Vector{Int}})
    setpred=Set(pred)
    setsucc=Set(succ_list[noeud])
    true_succ=setdiff(setsucc,intersect(setpred,setsucc))
    return true_succ
end

function True_succ_tree(tree::NewTreeNode,succ_list::Vector{Vector{Int}})
    return True_succ(tree.pred,tree.case,succ_list)
end

function heur(elt,new_pred,succ_list)
    if length(new_pred)<3
        return 10000
    end
    if length(new_pred)>=length(succ_list)-5
        return 10000
    end
    return length(succ_list[elt]) + (length(new_pred))
end

function Solve_Heur(succ_list,Contraintes_jeu)
    println(succ_list)
    pop!(succ_list)
    println(Contraintes_jeu)
    root=NewTreeNode(1,[])
    unsolved=true
    cur_succ=True_succ_tree(root,succ_list)
    candidate=[]
    cur_tree=root
    notskip=true

    while unsolved
        
        if cur_tree.case==length(succ_list)+1 && length(cur_tree.pred)==length(succ_list)
            unsolved=false
        else
            if notskip 
                new_pred=vcat(cur_tree.pred,[cur_tree.case])
                
                for elt in cur_succ
                    
                    push!(candidate,(NewTreeNode(elt,new_pred),heur(elt,new_pred,succ_list)))
                end
            
                #sort!(candidate,by=x->x[2]) #on a trié les candidats par heuristiques
            else
                notskip=true
            end
            
            cur_tree=popfirst!(candidate)[1]
            #println(cur_tree)
            if cur_tree.case==length(succ_list)+1
                notskip=false
            else
                cur_succ=True_succ_tree(cur_tree,succ_list)
                if in(length(cur_tree.pred)+1,Contraintes_jeu)
                    indice= findfirst(x->x==length(cur_tree.pred)+1,Contraintes_jeu)
                    #println(indice)
                    indice= (indice[1]-1)*size(Contraintes_jeu,1)+indice[2]
                    #println(indice)
                    if indice != cur_tree.case
                        notskip=false
                    end
                end
                
            end
            #println(notskip)
        end
    end
    return cur_tree
end