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
  <title>تعديل البيانات</title>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 flex justify-center items-center min-h-screen">
  <form method="POST" action="update.php" class="bg-white p-6 rounded-xl shadow-lg w-full max-w-lg">
    <input type="hidden" name="form" value="<?= $form ?>">
    <input type="hidden" name="id" value="<?= $id ?>">
    <?php foreach($data as $k=>$v): if($k=='id') continue; ?>
      <label class="block mb-2"><?= $k ?></label>
      <input name="<?= $k ?>" value="<?= htmlspecialchars($v) ?>" class="border p-2 w-full mb-3 rounded">
    <?php endforeach; ?>
    <button class="bg-indigo-600 text-white px-4 py-2 rounded">حفظ التعديلات</button>
  </form>
</body>
</html>
