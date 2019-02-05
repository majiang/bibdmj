module bibdmj;

import std.algorithm, std.array, std.range;

class HalvedTablesTCTSearcher : TripleCircleTournamentSearcher
{
    private this ()
    {
    }
    TripleCircleTournamentSearcher init(ParameterRelations parameterRelations)
    {
        assert (false);
    }
    TripleCircleTournament front()
    {
        assert (false);
    }
    void popFront()
    {
        assert (false);
    }
    bool empty()
    {
        assert (false);
    }
}

interface TripleCircleTournamentSearcher
{
    TripleCircleTournamentSearcher init(ParameterRelations parameterRelations);
    TripleCircleTournament front();
    void popFront();
    bool empty();
}

class TripleCircleTournament : PSTTournament
{
    size_t[][] playerSessionTable()
    {
        auto ret = new size_t[][](n_players, n_games);
        foreach (g; 0..n_games)
        {
            ret[centerPlayer][g] = centerTable;
            foreach (playerTable; players[].zip(tables[]))
            {
                foreach (position; 0..n_games)
                {
                    immutable
                        p = playerTable[0][position],
                        t = playerTable[1][(position + g) % n_games];
                    ret[p][g] = t;
                }
            }
        }
        return ret;
    }
    size_t centerPlayer, centerTable;
    size_t[][3] players, tables;
    ParameterRelations parameterRelations;
    alias parameterRelations this;
}


interface PSTTournament
{
    size_t[][] playerSessionTable()
    out (result)
    {
        foreach (game; result.map!(_=>_.dup).array.transposed)
            assert (game.array.sort.group.all!(_ => _[1] == 4));
    }
    final bool isBIBD()
    {
        auto pst = playerSessionTable;
        foreach (i, p; pst)
            foreach (j, q; pst[0..i])
                if (p.zip(q).count!(_=>_[0]==_[1]) != 1)
                    return false;
        return true;
    }
    final string toTSV()
    {
        import std.format;
        return "%(%(%d\t%)\n%)\n".format(playerSessionTable);
    }
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
