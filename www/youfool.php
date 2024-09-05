<?php
//This php page adds every not allowed ip to the deny list.

$remoteAddr = $_SERVER["REMOTE_ADDR"];
exec("sudo /usr/local/bin/apache-allow.sh honey $remoteAddr");

header("HTTP/1.1 403 Forbidden");
header("Status: 403 Forbidden");

echo "<h1>403 Forbidden</h1>";
echo "<p>You don't have permission to access this resource.</p>";
?>
