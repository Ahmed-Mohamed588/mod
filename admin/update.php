<?php
include '../config.php';
if(!isset($_SESSION['admin'])) { header("Location: login.php"); exit; }

$form = $_POST['form'];
$id = intval($_POST['id']);
$updates = [];
foreach($_POST as $k=>$v) {
  if(in_array($k, ['form','id'])) continue;
  $updates[] = "`$k`='" . $conn->real_escape_string($v) . "'";
}
$sql = "UPDATE form_$form SET " . implode(',', $updates) . " WHERE id=$id";
$conn->query($sql);
header("Location: view.php?form=$form&id=$id");
exit;
?>
