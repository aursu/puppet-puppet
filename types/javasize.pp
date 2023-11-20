type Puppet::JavaSize = Variant[
  Integer[0],
  Pattern[/\A\d+[k|K|m|M|g|G]?\z/],
]
