type Tree =
    | Leaf
    | Node of int * Tree * Tree

// рекурсивный обход в глубину с накоплением пути
let rec dfs (tree: Tree) (path: int list) =
    match tree with
    | Leaf -> ()
    | Node (value, left, right) ->
        let newPath = path @ [value]
        match left, right with
        | Leaf, Leaf ->
            let sum = List.sum newPath
            printfn "Path: %A, sum = %d" newPath sum
        | _ ->
            dfs left newPath
            dfs right newPath

let tree =
    Node (1,
        Node (2,
            Node (4, Leaf, Leaf),
            Node (5, Leaf, Leaf)),
        Node (3,
            Node (6, Leaf, Leaf),
            Leaf))

printfn "DFS traversal of binary tree:"
dfs tree []