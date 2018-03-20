type Puppet::Priority = Variant[
    Enum['high', 'normal', 'low', 'idle'],
    Integer
]