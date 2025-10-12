<?php
// تشغيل عرض الأخطاء أثناء التطوير
error_reporting(E_ALL);
ini_set('display_errors', 1);

include 'config.php';

// تحقق من الفورم
$form = $_POST['form_name'] ?? '';
if (!$form) {
    die("<p style='color:red;text-align:center;'>❌ نوع الفورم غير محدد</p>");
}

$table = "form_" . preg_replace('/[^a-z0-9_]/i', '', $form);

// تحقق من وجود الجدول فعلاً
$checkTable = $conn->query("SHOW TABLES LIKE '$table'");
if ($checkTable->num_rows === 0) {
    die("<p style='color:red;text-align:center;'>❌ الجدول المطلوب غير موجود في قاعدة البيانات ($table)</p>");
}

// تجهيز الأعمدة والقيم
$cols = [];
$vals = [];

foreach ($_POST as $key => $val) {
    if ($key === 'form_name') continue;
    $cols[] = "`" . $conn->real_escape_string($key) . "`";
    $vals[] = "'" . $conn->real_escape_string(trim($val)) . "'";
}

// التأكد من وجود بيانات
if (empty($cols)) {
    die("<p style='color:red;text-align:center;'>⚠️ لا توجد بيانات لإرسالها!</p>");
}

// تنفيذ الإدخال
$sql = "INSERT INTO `$table` (" . implode(',', $cols) . ") VALUES (" . implode(',', $vals) . ")";
if ($conn->query($sql)) {
    echo "<p style='color:green;text-align:center;font-weight:bold;'>✅ تم إرسال البيانات بنجاح!</p>";
    echo "<meta http-equiv='refresh' content='2;url=index.php'>";
} else {
    echo "<p style='color:red;text-align:center;'>❌ خطأ أثناء الحفظ: " . htmlspecialchars($conn->error) . "</p>";
}
?>
