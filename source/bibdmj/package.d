module bibdmj;

import std.algorithm, std.array, std.range;
import std.bitmanip;
import std.experimental.logger;

class LineSymmetryHalvedTablesTCTSearcher : TripleCircleTournamentSearcher
{
    this (ParameterRelations parameterRelations)
    {
        this.parameterRelations = parameterRelations;
        foreach (ref elem; this._candidates)
        {
            elem.length = n * 2;
            foreach (ref bit; elem)
                bit = true;
        }
        foreach (ref elem; this._relationsToCover)
        {
            elem.length = n * 2;
            foreach (ref bit; elem)
                bit = true;
        }
        foreach (i, ref elem; this.players)
            elem = (i*n_games).iota((i+1)*n_games).array;
        foreach (i, ref elem; this.tables)
            elem = new size_t[n_games];
    }
    int opApply(scope int delegate (ref TripleCircleTournament) dg)
    {
        return bfs(0, n_tables / n_circles, dg);
    }
    auto bfs(
            size_t circlePairIndex,
            size_t tablesRemaining,
            scope int delegate (ref TripleCircleTournament) dg
            )
    {
        if (circlePairIndex == n_circles)
        {
            auto tct = makeTCT;
            return dg(tct);
        }
        if (tablesRemaining == 0)
            if (auto res = bfs(circlePairIndex + 1, n_tables / n_circles, dg))
                return res;
        foreach (i; candidates(circlePairIndex))
        foreach (j; candidates((circlePairIndex + 1) % n_circles))
        {
            if (auto ok = place(circlePairIndex, tablesRemaining, i, j))
            {
                if (auto res = bfs(circlePairIndex, tablesRemaining - 1, dg))
                    return res;
                undoPlace(circlePairIndex, tablesRemaining, i, j);
            }
        }
        return 0;
    }
    bool place(size_t circlePairIndex, size_t tablesRemaining, size_t i, size_t j)
    {
        "place(%d %d %d %d)".tracef(circlePairIndex, tablesRemaining, i, j);
        if (i == j)
            return false;
        auto rs = newlyCovered(i, j);
        "rs: %s".tracef(rs);
        if (!(_relationsToCover[circlePairIndex][rs[0]-1] && _relationsToCover[circlePairIndex][rs[1]-1]))
        {
            "already covered: %s".tracef(_relationsToCover[circlePairIndex]);
            return false;
        }
        setRelation(circlePairIndex, rs[0], false);
        setRelation(circlePairIndex, rs[1], false);
        setCandidates(circlePairIndex, i, false);
        setCandidates((circlePairIndex + 1) % n_circles, j, false);
        auto tableNumber = (circlePairIndex + 1) * n - tablesRemaining;
        "tables[%d,+1%%3][%d,%d,%d,%d]".tracef(
                circlePairIndex, i, n_games-i, j, n_games-j);
        import std.format;
        assert (tableNumber<size_t.max>>1, "table = (%d+1)*%d-%d".format(circlePairIndex, n, tablesRemaining));
        tables[circlePairIndex][i] = tableNumber;
        tables[circlePairIndex][n_games-i] = tableNumber;
        tables[(circlePairIndex+1)%n_circles][j] = tableNumber;
        tables[(circlePairIndex+1)%n_circles][n_games - j] = tableNumber;
        return true;
    }
    void undoPlace(size_t circlePairIndex, size_t tablesRemaining, size_t i, size_t j)
    {
        auto rs = newlyCovered(i, j);
        setRelation(circlePairIndex, rs[0], true);
        setRelation(circlePairIndex, rs[1], true);
        setCandidates(circlePairIndex, i, true);
        setCandidates((circlePairIndex + 1) % n_circles, j, true);
    }
    size_t[2] newlyCovered(size_t i, size_t j)
    {
        if (i < j)
            return newlyCovered(j, i);
        return [absmod(i-j), absmod(i+j)];
    }
    size_t absmod(size_t v)
    {
        auto r = v % n_games;
        return r.min(n_games - r);
    }
    auto candidates(size_t circleIndex)
    {
        assert (circleIndex < 3);
        return _candidates[circleIndex].bitsSet.map!(_=>_+1).array;
    }
    void setCandidates(size_t circleIndex, size_t i, bool value)
    {
        _candidates[circleIndex][i-1] = value;
    }
    void setRelation(size_t circleIndex, size_t i, bool value)
    {
        _relationsToCover[circleIndex][i-1] = value;
    }
    BitArray[3] _candidates;
    BitArray[3] _relationsToCover;
    size_t[][3] currentSolution;
    auto makeTCT()
    {
        return new TripleCircleTournament(
                parameterRelations,
                n_players - 1, n_tables - 1,
                players, tables
            );
    }
    size_t[][3] players, tables;

    ParameterRelations parameterRelations;
    alias parameterRelations this;
    enum n_circles = 3;
}

interface TripleCircleTournamentSearcher
{
    int opApply(scope int delegate (ref TripleCircleTournament) dg);
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
    this (ParameterRelations parameterRelations,
            size_t centerPlayer, size_t centerTable,
            size_t[][3] players, size_t[][3] tables)
    {
        this.parameterRelations = parameterRelations;
        this.centerPlayer = centerPlayer;
        this.centerTable = centerTable;
        this.players = players;
        this.tables = tables;
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
        //foreach (game; result.map!(_=>_.dup).array.transposed)
        //    assert (game.array.sort.group.all!(_ => _[1] == 4));
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
