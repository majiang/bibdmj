void main(string[] args)
{
    import std.stdio, std.conv;

    immutable n = args[1].to!size_t;
    ParameterRelations(n).writeln;
}

struct ParameterRelations
{
    this (size_t n)
    {
        this.n = n;
        this.n_tables = (playerPerTable - 1) * n + 1;
        this.n_players = n_tables * playerPerTable;
        this.n_games = playerPerTable * n + 1;
    }
    immutable size_t
        n, n_tables, n_players, n_games;
    enum size_t playerPerTable = 4;
}
