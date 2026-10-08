# топологическая сортировка ориентированного графа через рекурсивный DFS

# граф задан списком смежности: Dict[вершина -> список соседей]
function build_graph(edges)
    g = Dict{Int, Vector{Int}}()
    for (u, v) in edges
        push!(get!(g, u, Int[]), v)
        get!(g, v, Int[])  # чтобы вершина была в графе, даже если без исходящих рёбер
    end
    return g
end

# рекурсивный DFS: возвращает true, если цикла нет
function dfs!(g, v, visited, in_stack, order)
    visited[v] = true
    in_stack[v] = true

    for u in get(g, v, Int[])
        if !visited[u]
            if !dfs!(g, u, visited, in_stack, order)
                return false
            end
        elseif in_stack[u]
            # нашли обратное ребро — цикл
            return false
        end
    end

    in_stack[v] = false
    push!(order, v)
    return true
end

function toposort(g)
    visited = Dict{Int, Bool}()
    in_stack = Dict{Int, Bool}()
    order = Int[]

    for v in keys(g)
        visited[v] = false
        in_stack[v] = false
    end

    for v in keys(g)
        if !visited[v]
            if !dfs!(g, v, visited, in_stack, order)
                return nothing  # цикл
            end
        end
    end

    return reverse(order)
end

function main()
    edges = [
        (5, 2),
        (5, 0),
        (4, 0),
        (4, 1),
        (2, 3),
        (3, 1),
    ]

    g = build_graph(edges)
    println("Graph: ", length(g), " vertices, ", length(edges), " edges")

    order = toposort(g)

    if order === nothing
        println("Graph contains a cycle, topological sort is impossible.")
    else
        println("Topological order: ", join(order, " "))
    end

    edges_cyclic = [(0, 1), (1, 2), (2, 0)]
    g2 = build_graph(edges_cyclic)
    println()
    println("Cyclic graph check:")
    order2 = toposort(g2)
    if order2 === nothing
        println("Graph contains a cycle, topological sort is impossible.")
    else
        println("Topological order: ", join(order2, " "))
    end
end

main()