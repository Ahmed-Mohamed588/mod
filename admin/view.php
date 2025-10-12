<?php
include '../config.php';
if(!isset($_SESSION['admin'])) { header("Location: login.php"); exit; }

$form = $_GET['form'];
$id = intval($_GET['id']);
$res = $conn->query("SELECT * FROM form_$form WHERE id=$id");
$data = $res->fetch_assoc();
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>عرض البيانات</title>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 flex justify-center items-center min-h-screen">
  <div class="bg-white p-6 rounded-xl shadow-lg w-full max-w-lg">
    <h2 class="text-xl font-bold text-indigo-700 mb-4">بيانات الفورم</h2>
    <?php foreach($data as $k=>$v): if($k=='id') continue; ?>
      <p class="mb-2"><strong><?= $k ?>:</strong> <?= htmlspecialchars($v) ?></p>
    <?php endforeach; ?>
    <div class="flex justify-between mt-4">
      <a href="edit.php?form=<?= $form ?>&id=<?= $id ?>" class="bg-yellow-500 text-white px-4 py-2 rounded">تعديل</a>
      <a href="print.php?form=<?= $form ?>&id=<?= $id ?>" target="_blank" class="bg-green-600 text-white px-4 py-2 rounded">طباعة</a>
    </div>
  </div>
</body>
</html>
