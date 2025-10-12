<?php
if (!isset($_GET['form']) || empty($_GET['form'])) {
    http_response_code(400);
    echo "لم يتم تحديد الفورم المطلوب";
    exit;
}
$form = preg_replace('/[^a-z0-9_]/i', '', $_GET['form']);
$file = "forms/$form.php";
if (!file_exists($file)) {
    http_response_code(404);
    echo "الفورم غير موجود";
    exit;
}
include $file;
?>
