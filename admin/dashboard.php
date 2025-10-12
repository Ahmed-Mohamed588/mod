<?php
include '../config.php';
if(!isset($_SESSION['admin'])) { header("Location: login.php"); exit; }

// هنا نحدد الفورم اللي عايزين نعرضه
$form_key = 'national_id'; 
$form_label = 'بيانات الرقم القومي';

$sql = "SELECT * FROM form_$form_key ORDER BY id DESC";
$res = $conn->query($sql);
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>لوحة إدارة - <?= $form_label ?></title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
</head>
<body class="bg-gray-100 min-h-screen">
  <div class="max-w-6xl mx-auto mt-8 bg-white shadow-xl p-6 rounded-2xl">
    
    <!-- Header -->
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-indigo-700">📋 <?= $form_label ?></h1>
      <a href="logout.php" class="text-red-600 hover:text-red-700">تسجيل الخروج</a>
    </div>

    <!-- Search -->
    <div class="mb-6">
      <input id="searchInput" type="text" placeholder="ابحث برقم الهاتف..." class="border border-gray-300 p-3 rounded-lg w-full focus:outline-none focus:ring-2 focus:ring-indigo-500">
    </div>

    <!-- Table -->
    <div class="border border-gray-200 rounded-xl p-5 shadow-sm bg-gray-50">
      <div class="flex items-center justify-between mb-3">
        <h2 class="text-xl font-semibold text-indigo-700"><?= $form_label ?></h2>
        <span class="text-sm text-gray-500">عدد السجلات: <?= $res ? $res->num_rows : 0 ?></span>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-sm text-right border">
          <thead class="bg-indigo-100 text-indigo-800">
            <tr>
              <th class="p-2 border">#</th>
              <th class="p-2 border">رقم الهاتف</th>
              <th class="p-2 border">الرقم القومي</th>
              <th class="p-2 border">اسم المستفيد</th>
              <th class="p-2 border text-center">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            <?php if($res && $res->num_rows > 0): $i=1; while($row = $res->fetch_assoc()): ?>
              <tr class="border-b bg-white hover:bg-indigo-50 transition" data-phone="<?= htmlspecialchars($row['phone'] ?? '') ?>">
                <td class="p-2 border"><?= $i++ ?></td>
                <td class="p-2 border"><?= htmlspecialchars($row['phone'] ?? '-') ?></td>
                <td class="p-2 border"><?= htmlspecialchars($row['national_id'] ?? '-') ?></td>
                <td class="p-2 border"><?= htmlspecialchars($row['beneficiary_name'] ?? '-') ?></td>
                <td class="p-2 border text-center">
                  <a href="view.php?form=<?= $form_key ?>&id=<?= $row['id'] ?>" class="text-indigo-600 hover:text-indigo-800 font-medium">عرض</a>
                </td>
              </tr>
            <?php endwhile; else: ?>
              <tr><td colspan="5" class="p-4 text-center text-gray-500">لا توجد بيانات حالياً</td></tr>
            <?php endif; ?>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <script>
    // بحث فوري بالـ JavaScript
    $("#searchInput").on("keyup", function() {
      const value = $(this).val().toLowerCase().trim();
      $("tr[data-phone]").each(function() {
        const phone = $(this).data("phone").toString().toLowerCase();
        $(this).toggle(phone.includes(value));
      });
    });
  </script>
</body>
</html>
