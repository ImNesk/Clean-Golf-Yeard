$ErrorActionPreference = "Stop"

$in = "Clean_Golf_Yard_Farm.lua"
$out = "Clean_Golf_Yard_Farm_obfuscated.lua"
$loader = "Clean_Golf_Yard_Farm_loader.lua"

$src = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot $in))

$lines = $src -split "`r?`n"
$cleanLines = @()
foreach ($l in $lines) {
    $t = $l.Trim()
    if ($t -eq "") { continue }
    if ($t -match "^\-\-") { continue }
    $cleanLines += $l
}
$clean = ($cleanLines -join "`n")

$bytes = [System.Text.Encoding]::UTF8.GetBytes($clean)

$rng = New-Object System.Random
$keyLen = $rng.Next(4, 9)
$key = New-Object byte[] $keyLen
$rng.NextBytes($key)

$xored = New-Object byte[] $bytes.Length
for ($i = 0; $i -lt $bytes.Length; $i++) {
    $xored[$i] = $bytes[$i] -bxor $key[$i % $keyLen]
}
$payload = [System.Convert]::ToBase64String($xored)
$keyStr = ($key | ForEach-Object { $_ }) -join ","

$decoder = @"
local K = {$keyStr}
local s = [[$payload]]
local function bxor(a, b)
	local r = 0
	local p = 1
	while a > 0 or b > 0 do
		local da = a % 2
		local db = b % 2
		if da ~= db then r = r + p end
		a = math.floor(a / 2)
		b = math.floor(b / 2)
		p = p * 2
	end
	return r
end
local function b64(s)
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local t = {}
	for i = 1, 64 do t[chars:sub(i, i)] = i - 1 end
	s = s:gsub("=+$", "")
	local out, o = {}, 1
	for i = 1, #s, 4 do
		local a = t[s:sub(i, i)] or 0
		local b = t[s:sub(i + 1, i + 1)] or 0
		local c = t[s:sub(i + 2, i + 2)] or 0
		local d = t[s:sub(i + 3, i + 3)] or 0
		local n = a * 262144 + b * 4096 + c * 64 + d
		out[o] = string.char(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
		o = o + 1
	end
	local r = table.concat(out)
	return r:sub(1, math.floor(#s * 3 / 4))
end
local function de(s)
	local raw = b64(s)
	local out = {}
	local keyLen = #K
	for i = 1, #raw do
		out[i] = string.char(bxor(raw:byte(i), K[((i - 1) % keyLen) + 1]))
	end
	return table.concat(out)
end
if not game then error("invalid environment") end
local f = loadstring or load
if not f then error("no loader") end
local fn, err = f(de(s))
if not fn then error("decode error: " .. tostring(err)) end
fn()
"@

[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot $out), $decoder, (New-Object System.Text.UTF8Encoding($false)))

$wrapped = "loadstring([=[" + "`n" + $decoder + "`n" + "]=])()" + "`n"
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot $loader), $wrapped, (New-Object System.Text.UTF8Encoding($false)))

$raw = [System.Convert]::FromBase64String($payload)
$verify = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt $raw.Length; $i++) {
    $dec = $raw[$i] -bxor $key[$i % $keyLen]
    [void]$verify.Append([char]$dec)
}
if ($verify.ToString() -ne $clean) {
    Write-Output "VERIFY FAILED"
    exit 1
}

Write-Output "OK - original $($bytes.Length) bytes -> payload $($payload.Length) chars (base64), key len $keyLen"
Write-Output "out: $out / $loader"
