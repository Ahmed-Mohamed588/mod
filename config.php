<?php
$host = "localhost";
$user = "u389014136_form";
$pass = "9SE+vK|e";
$db   = "u389014136_form";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die("فشل الاتصال بقاعدة البيانات: " . $conn->connect_error);
}
$conn->set_charset("utf8mb4");
session_start();
?>
