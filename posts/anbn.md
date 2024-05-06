# Parsing a simple formal language using F\#

There is a field of study at the intersection of linguistics, mathematics, and computer science dedicated to characterization of sets of finite strings: formal language theory. A formal language is literally just a set containing strings drawn from some alphabet. For example, the set $L_0 = \{a, b, c\}$ is the formal language consisting of the strings "a", "b", and "c" and nothing else. The three letters "a", "b", and "c" make up the alphabet.

In this post, I will concentrate on the language $L = \{a^n b^n\}$: the set of all strings containing $n \geq 1$ "a"s follows b $n$ "b"s. This language belongs to the class of [context-free languages](https://en.wikipedia.org/wiki/Context-free_language). There's a lot of interesting things to discuss with context-free languages and formal language theory, especially with regard to how natural (human) languages relate to formal languages (see *Mathematical Methods in Linguistics* by Partee, ter Meulen, and Wall, 1990 for a really good introduction). But today, I just want to implement a simple parser (pushdown automaton) for language $L$ using the F\# programming language.

The parser will work like this: It scans the string one letter at a time. If it encounters an "a", it adds 1 to its counter. (Because there are only two accepted symbols in the alphabet, "a", and "b", we actually only need to track the depth of the stack and not its contents). When it encounters a "b", it decreases its counter by 1. All other symbols in the input are ignored.

To implement this in F\#, we start by defining a stack record type, a data structure that just contains a named element for the stack depth:

```fsharp
type Stack = {
    depth: int
}
```

The parser is written as a simple command line program that takes a string as input. In order separate the string into characters and remove any characters that aren't "a" or "b", I use the following function:

```fsharp
let sepInput (input: string) =
    input.ToCharArray()
    |> Array.toList
    |> List.filter (fun x -> x = 'a' || x = 'b')
```

Now comes the main function to actually process the input and determine whether it belongs the language $L$.

```fsharp
let parse (input: string) =
    let ipt = sepInput input

    // Inner recursive function that works its way through the input
    let rec innerparse lst stck =
        match lst with
        | [] -> stck
        | head :: rest when head = 'a' -> innerparse rest {stck with depth = stck.depth + 1}
        | head :: rest when head = 'b' -> innerparse rest {stck with depth = stck.depth - 1}
        // Should never get here, but needed for completeness of pattern match
        | head :: rest -> innerparse rest stck
    
    let stack = innerparse ipt {depth = 0}

    match stack.depth with
    | 0 -> true
    | _ -> false
```

