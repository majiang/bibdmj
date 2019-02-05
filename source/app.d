void main(string[] args)
{
    import std.stdio, std.conv, bibdmj;

    immutable n = args[1].to!size_t;
    ParameterRelations(n).writeln;
}
