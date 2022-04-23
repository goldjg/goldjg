$servers = get-content \\##REDACTED##\RDP_Group.txt
foreach ($server in $servers) {
	mstsc /v:$server /w:1024 /h:768;}

