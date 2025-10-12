<?php
include 'config.php';
$forms = include 'forms_list.php';
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>الصفحة الرئيسية</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
</head>
<body class="bg-gray-100 min-h-screen flex items-center justify-center">
  <div class="bg-white shadow-xl rounded-2xl p-8 w-full max-w-3xl">
    <h1 class="text-2xl font-bold text-indigo-700 text-center mb-6">اختر الفورم الذي ترغب في تعبئته</h1>
    <select id="formSelector" class="border rounded-lg p-3 w-full mb-5">
      <option value="">-- اختر فورم --</option>
      <?php foreach ($forms as $key => $label): ?>
        <option value="<?= $key ?>"><?= $label ?></option>
      <?php endforeach; ?>
    </select>
    <div id="formContainer"></div>
  </div>

  <script>
    $("#formSelector").on("change", function() {
      const name = $(this).val();
      if(!name) return $("#formContainer").html('');
      $("#formContainer").html('<p class="text-gray-500 text-center">جار التحميل...</p>');
      $.get("load_form.php", {form: name}, res => $("#formContainer").html(res));
    });
  </script>
</body>
</html>
