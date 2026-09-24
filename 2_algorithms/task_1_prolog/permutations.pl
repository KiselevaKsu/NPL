% все перестановки списка через перебор с возвратом

permute([], []).

permute(List, [X|Rest]) :-
    select(X, List, Remaining),
    permute(Remaining, Rest).

main :-
    String = "abc",
    string_chars(String, Chars),
    findall(P, permute(Chars, P), AllPerms),
    length(AllPerms, Count),
    format("All permutations of ~w:~n", [String]),
    forall(member(P, AllPerms),
           (atomic_list_concat(P, '', Atom),
            format("  ~w~n", [Atom]))),
    format("Total permutations: ~w~n", [Count]).