<?php
//this php script adds or updates the incomming ip address to home assistant to be allowed or denied.

$remoteAddr = $_SERVER["REMOTE_ADDR"];
exec("sudo /usr/local/bin/apache-allow.sh check $remoteAddr"); 

header("HTTP/1.1 403 Forbidden");
header("Status: 403 Forbidden");

echo "<h1>403 Forbidden</h1>";
echo "<p>You don't have permission to access this resource.</p>";
?>


