void main(string[] args)
{
    import std.stdio, std.conv, bibdmj;
    import std.experimental.logger;
    sharedLog.logLevel = LogLevel.info;

    immutable n = args[1].to!size_t;
    ParameterRelations(n).writeln;
    foreach (tct; cast(TripleCircleTournamentSearcher)new LineSymmetryHalvedTablesTCTSearcher(ParameterRelations(n)))
    {
        tct.toTSV.writeln;
    }
}
