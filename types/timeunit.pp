type Puppet::TimeUnit = Variant[
    Integer,
    Pattern[/^[0-9]+[ydhms]?$/]
]