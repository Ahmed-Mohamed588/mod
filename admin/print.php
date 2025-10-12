<?php
include '../config.php';
$form = $_GET['form'];
$id = intval($_GET['id']);
$res = $conn->query("SELECT * FROM form_$form WHERE id=$id");
$data = $res->fetch_assoc();
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>طباعة الفورم</title>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body onload="window.print()" class="p-8">
  <h1 class="text-center text-2xl font-bold mb-5">نموذج <?= htmlspecialchars($form) ?></h1>
  <?php foreach($data as $k=>$v): if($k=='id') continue; ?>
    <p><strong><?= $k ?>:</strong> <?= htmlspecialchars($v) ?></p>
  <?php endforeach; ?>
</body>
</html>
