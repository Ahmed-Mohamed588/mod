<?php
include '../config.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $user = $_POST['username'];
    $pass = $_POST['password'];
    $sql = "SELECT * FROM admins WHERE username='$user' AND password='$pass'";
    $result = $conn->query($sql);
    if ($result->num_rows > 0) {
        $_SESSION['admin'] = $user;
        header("Location: dashboard.php");
        exit;
    } else {
        $error = "بيانات الدخول غير صحيحة!";
    }
}
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <script src="https://cdn.tailwindcss.com"></script>
  <title>تسجيل الدخول</title>
</head>
<body class="bg-gray-100 flex items-center justify-center min-h-screen">
  <form method="POST" class="bg-white shadow-lg p-6 rounded-2xl w-full max-w-md">
    <h2 class="text-center text-2xl mb-4 font-bold text-indigo-700">تسجيل الدخول للوحة الإدارة</h2>
    <?php if(!empty($error)): ?>
      <p class="text-red-600 text-center mb-3"><?= $error ?></p>
    <?php endif; ?>
    <input name="username" placeholder="اسم المستخدم" class="border p-2 w-full mb-3 rounded" required>
    <input name="password" type="password" placeholder="كلمة المرور" class="border p-2 w-full mb-3 rounded" required>
    <button class="bg-indigo-600 text-white w-full py-2 rounded">دخول</button>
    <p class="text-center mt-3 text-sm">ليس لديك حساب؟ <a href="register.php" class="text-indigo-600">إنشاء حساب</a></p>
  </form>
</body>
</html>
