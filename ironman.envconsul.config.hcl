log_level = "warn"
max_stale = "10m"
pristine  = true
retry     = "10s"
sanitize  = true
timeout   = "5s"
upcase    = true

prefix {
  path = "configuration/globals"
}

prefix {
  path = "configuration/datacenters"
}

prefix {
  path = "configuration/datacenters/lax"
}

prefix {
  path = "configuration/applications"
}

prefix {
  path = "configuration/applications/ag"
}

prefix {
  path = "configuration/environments"
}

prefix {
  path = "configuration/environments/qa"
}

prefix {
  path = "configuration/clusters"
}

prefix {
  path = "configuration/hosts"
}

prefix {
  path = "configuration/hosts/ironman"
}
