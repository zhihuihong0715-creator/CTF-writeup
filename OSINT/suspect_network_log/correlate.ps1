function Get-SessionMap {
    param($Path, $Pattern)
    $map = @{}
    Select-String -Path $Path -Pattern $Pattern | ForEach-Object {
        $session = $_.Matches.Groups[1].Value
        $host_ = $_.Matches.Groups[2].Value
        if (-not $map.ContainsKey($host_)) { $map[$host_] = [System.Collections.Generic.HashSet[string]]::new() }
        [void]$map[$host_].Add($session)
    }
    return $map
}

$fwMap = Get-SessionMap -Path "firewall.log" -Pattern 'session=(\S+) src=\S+ dst=[\d.]+:\d+ .*host=(\S+)'
$dnsMap = Get-SessionMap -Path "dns_queries.log" -Pattern 'session=(\S+) client=\S+ query=(\S+)'
$proxyMap = Get-SessionMap -Path "proxy_access.log" -Pattern 'session=(\S+) client=\S+ host=(\S+)'

foreach ($host_ in $fwMap.Keys) {
    if ($dnsMap.ContainsKey($host_) -and $proxyMap.ContainsKey($host_)) {
        $shared = [System.Collections.Generic.HashSet[string]]::new($fwMap[$host_])
        $shared.IntersectWith($dnsMap[$host_])
        $shared.IntersectWith($proxyMap[$host_])
        if ($shared.Count -gt 0) {
            Write-Host "$host_ -> $($shared -join ', ')"
        }
    }
}