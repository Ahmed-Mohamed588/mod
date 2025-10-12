<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>فورم الرقم القومي</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
</head>

<body class="bg-gradient-to-br from-gray-50 to-gray-100 p-8 min-h-screen font-[Cairo,sans-serif]">

  <form method="POST" action="submit_form.php" class="max-w-6xl mx-auto bg-white p-10 rounded-xl shadow-lg border border-gray-200">
    <input type="hidden" name="form_name" value="national_id">

    <!-- ===== الصف الأول ===== -->
    <div class="grid grid-cols-3 gap-6 mb-8">
      <div class="text-right">
        <label class="block text-sm font-medium mb-3">رقم الهاتف الاجتماعي <span class="text-red-500">*</span></label>
        <input type="text" name="social_phone" required placeholder="رقم الهاتف الاجتماعي (8 أرقام)" class="border border-gray-300 p-3 rounded w-full text-right text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-200">
      </div>

      <div class="text-right">
        <label class="block text-sm font-medium mb-3">الرقم المحلي <span class="text-red-500">*</span></label>
        <input type="text" name="private_number" required placeholder="الرقم المحلي (12 رقم)" class="border border-gray-300 p-3 rounded w-full text-right text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-200">
      </div>

      <div class="text-right">
        <label class="block text-sm font-medium mb-3">الرقم القومي <span class="text-red-500">*</span></label>
        <input type="text" id="national_id" name="national_id" maxlength="14" required placeholder="الرقم القومي (14 رقم)" class="border border-gray-300 p-3 rounded w-full text-right text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-200">
      </div>
    </div>

    <!-- ===== نوع الهوية ===== -->
    <div class="grid grid-cols-2 gap-6 mt-6">
      <label class="cursor-pointer">
        <div id="passport_box" class="p-6 bg-gray-50 border-2 border-gray-300 rounded text-center hover:border-blue-400 transition-all">
          <div class="flex items-center justify-center gap-2 mb-3">
            <input type="radio" name="id_type" value="passport" class="w-5 h-5">
            <span class="text-base font-medium">جواز سفر مصري</span>
          </div>
        </div>
      </label>

      <label class="cursor-pointer">
        <div id="national_box" class="p-6 bg-blue-50 border-2 border-blue-500 rounded text-center transition-all">
          <div class="flex items-center justify-center gap-2 mb-3">
            <input type="radio" name="id_type" value="national" class="w-5 h-5" checked>
            <span class="text-base font-medium">بطاقة الرقم القومي</span>
          </div>
          <div class="text-sm text-gray-600 mt-2" id="national_id_display"></div>
        </div>
      </label>
    </div>

    <!-- ===== رقم الهوية ===== -->
    <div class="mt-6 text-center">
      <input type="text" id="extracted_national_id" name="extracted_national_id" readonly placeholder="الرقم القومي سيظهر تلقائيًا" class="border border-gray-300 p-3 rounded w-full bg-gray-100 text-center text-sm text-gray-500">
    </div>

    <!-- ===== رقم جواز السفر ===== -->
    <div id="passport_number_field" class="text-right hidden mt-6">
      <label class="block text-base font-medium mb-3">رقم جواز السفر <span class="text-red-500">*</span></label>
      <input type="text" id="passport_number" name="passport_number" placeholder="ادخل رقم جواز السفر" class="border border-gray-300 p-3 rounded w-full text-right text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-200">
    </div>

    <!-- ===== بيانات الشخص ===== -->
    <div class="text-right mt-8">
      <label class="block text-base font-medium mb-3 text-red-600">اسم الشخص المُوكل <span class="text-red-500">*</span></label>
      <input type="text" name="beneficiary_name" placeholder="الاسم كاملاً بالعربية" class="border border-gray-300 p-3 rounded w-full text-right text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-200">
    </div>

    <div class="text-right mt-6">
      <label class="block text-base font-medium mb-3">العلاقة</label>
      <textarea name="relation" rows="4" placeholder="عن نفسي / بصفتي وكيلاً عن ..." class="border border-gray-300 p-3 rounded w-full text-right text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-200 resize-y"></textarea>
    </div>

    <!-- ===== التواريخ ===== -->
    <div class="grid grid-cols-2 gap-8 mt-8">
      <!-- الانتهاء -->
      <div class="text-right">
        <label class="block text-base font-medium mb-4"><span id="expiry_label">تاريخ انتهاء بطاقة الرقم القومي</span> <span class="text-red-500">*</span></label>
        <div class="grid grid-cols-3 gap-4">
          <div>
            <label class="block text-xs text-gray-600 mb-2 text-center">السنة</label>
            <select id="expiry_year" name="expiry_year" disabled class="border border-gray-300 p-3 rounded w-full text-center text-sm bg-gray-50 cursor-not-allowed">
              <option value="">السنة</option>
            </select>
          </div>
          <div>
            <label class="block text-xs text-gray-600 mb-2 text-center">الشهر</label>
            <select id="expiry_month" name="expiry_month" disabled class="border border-gray-300 p-3 rounded w-full text-center text-sm bg-gray-50 cursor-not-allowed">
              <option value="">الشهر</option>
            </select>
          </div>
          <div id="expiry_day_container" class="hidden">
            <label class="block text-xs text-gray-600 mb-2 text-center">اليوم</label>
            <input type="text" id="expiry_day" name="expiry_day" maxlength="2" disabled class="border border-gray-300 p-3 rounded w-full text-center text-sm bg-gray-50 cursor-not-allowed">
          </div>
        </div>
      </div>

      <!-- الإصدار -->
      <div class="text-right">
        <label class="block text-base font-medium mb-4"><span id="issue_label">تاريخ إصدار بطاقة الرقم القومي</span> <span class="text-red-500">*</span></label>
        <div class="grid grid-cols-3 gap-4">
          <div>
            <label class="block text-xs text-gray-600 mb-2 text-center">السنة</label>
            <select id="issue_year" name="issue_year" class="border border-gray-300 p-3 rounded w-full text-center text-sm">
              <option value="">السنة</option>
            </select>
          </div>
          <div>
            <label class="block text-xs text-gray-600 mb-2 text-center">الشهر</label>
            <select id="issue_month" name="issue_month" class="border border-gray-300 p-3 rounded w-full text-center text-sm">
              <option value="">الشهر</option>
              <option value="1">يناير</option>
              <option value="2">فبراير</option>
              <option value="3">مارس</option>
              <option value="4">أبريل</option>
              <option value="5">مايو</option>
              <option value="6">يونيو</option>
              <option value="7">يوليو</option>
              <option value="8">أغسطس</option>
              <option value="9">سبتمبر</option>
              <option value="10">أكتوبر</option>
              <option value="11">نوفمبر</option>
              <option value="12">ديسمبر</option>
            </select>
          </div>
          <div id="issue_day_container" class="hidden">
            <label class="block text-xs text-gray-600 mb-2 text-center">اليوم</label>
            <input type="text" id="issue_day" name="issue_day" maxlength="2" class="border border-gray-300 p-3 rounded w-full text-center text-sm">
          </div>
        </div>
      </div>
    </div>

    <!-- ===== الجنسية + الوكلاء ===== -->
    <div class="border-2 border-gray-300 rounded-lg p-6 space-y-6 bg-gray-50 mt-10">
      <div class="text-right">
        <label class="block text-base font-medium mb-4">الجنسية <span class="text-red-500">*</span></label>
        <select name="nationality" class="border border-gray-300 p-3 rounded w-full text-right text-sm">
          <option value="">اختر</option>
          <option value="مصر">مصر</option>
          <option value="الكويت">الكويت</option>
          <option value="السعودية">السعودية</option>
          <option value="الإمارات">الإمارات</option>
          <option value="أخرى">أخرى</option>
        </select>
      </div>

      <div id="additional_attorneys" class="space-y-6">
        <div class="grid grid-cols-2 gap-6">
          <div class="text-right">
            <label class="block text-base font-medium mb-3">اسم الموكل إليه</label>
            <input type="text" name="attorney_name" placeholder="الاسم كاملاً" class="border border-gray-300 p-3 rounded w-full text-right text-sm">
          </div>

          <div class="text-right">
            <label class="block text-base font-medium mb-3">الرقم القومي للموكل إليه</label>
            <input type="text" name="attorney_national_id" maxlength="14" placeholder="الرقم القومي (14 رقم)" class="border border-gray-300 p-3 rounded w-full text-right text-sm">
          </div>
        </div>
      </div>

      <div class="text-left">
        <button type="button" id="add_attorney_btn" class="bg-yellow-500 hover:bg-yellow-600 text-white px-6 py-2 rounded text-sm transition">+ إضافة وكيل آخر</button>
      </div>

      <div class="text-right">
        <label class="block text-base font-medium mb-4">نوع التوكيل</label>
        <div class="flex items-center justify-end gap-8">
          <label class="flex items-center gap-2 cursor-pointer"><input type="radio" name="attorney_type" value="special" class="w-5 h-5">توكيل خاص</label>
          <label class="flex items-center gap-2 cursor-pointer"><input type="radio" name="attorney_type" value="general" class="w-5 h-5" checked>توكيل عام</label>
        </div>
      </div>

      <div class="text-right">
        <label class="block text-base font-medium mb-4">تفاصيل التوكيل</label>
        <textarea name="attorney_details" rows="4" placeholder="اكتب تفاصيل التوكيل هنا..." class="border border-gray-300 p-3 rounded w-full text-right text-sm resize-y"></textarea>
      </div>

      <div class="text-right">
        <label class="block text-base font-medium mb-4">إقرار إضافي (اختياري)</label>
        <textarea name="declaration" rows="3" placeholder="اكتب أي إقرار إضافي هنا..." class="border border-gray-300 p-3 rounded w-full text-right text-sm resize-y"></textarea>
      </div>

      <label class="flex items-center gap-2 cursor-pointer">
        <input type="checkbox" name="add_to_formula" class="w-5 h-5">
        <span class="text-sm">وذلك له الحق في (توكيل الغير في كل ما ذكر)</span>
      </label>
    </div>

    <!-- ===== زر الإرسال ===== -->
    <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-10 py-3 rounded-lg text-sm mt-8 block mx-auto">إرسال</button>
  </form>

  <!-- ===== السكريبت ===== -->
  <script>
    // عرض الرقم القومي في حقل المستخرج
    $('#national_id').on('input', function() {
      const val = $(this).val();
      $('#extracted_national_id').val(val);
      $('#national_id_display').text(val);
    });

    // ملء السنوات
    const currentYear = new Date().getFullYear();
    for (let y = 1950; y <= currentYear; y++) {
      $('#issue_year').append(`<option value="${y}">${y}</option>`);
    }

    // منع القيم غير الرقمية
    $('#issue_day, #expiry_day').on('input', function() {
      this.value = this.value.replace(/[^0-9]/g, '');
      if (this.value > 31) this.value = 31;
      if (this.value < 1 && this.value !== '') this.value = 1;
    });

    // نوع الوثيقة
    let docType = 'national';
    $('input[name="id_type"]').on('change', function() {
      docType = $(this).val();
      const isPassport = docType === 'passport';

      $('#passport_box').toggleClass('bg-blue-50 border-blue-500', isPassport).toggleClass('bg-gray-50 border-gray-300', !isPassport);
      $('#national_box').toggleClass('bg-blue-50 border-blue-500', !isPassport).toggleClass('bg-gray-50 border-gray-300', isPassport);
      $('#passport_number_field').toggle(isPassport);
      $('#issue_day_container, #expiry_day_container').toggle(isPassport);
      $('#issue_label').text(isPassport ? 'تاريخ إصدار جواز السفر' : 'تاريخ إصدار بطاقة الرقم القومي');
      $('#expiry_label').text(isPassport ? 'تاريخ انتهاء جواز السفر' : 'تاريخ انتهاء بطاقة الرقم القومي');
    });

    // حساب تاريخ الانتهاء
    function calcExpiry() {
      const y = parseInt($('#issue_year').val());
      const m = parseInt($('#issue_month').val());
      if (!y || !m) return;

      const expYear = y + 7;
      $('#expiry_year').html('<option value="">السنة</option>');
      for (let yr = y; yr <= y + 10; yr++) $('#expiry_year').append(`<option value="${yr}">${yr}</option>`);
      $('#expiry_month').html($('#issue_month').html());
      $('#expiry_year').val(expYear);
      $('#expiry_month').val(m);
    }
    $('#issue_year, #issue_month').on('change', calcExpiry);

    // إضافة وكلاء إضافيين
    let count = 1;
    const maxCount = 7;
    $('#add_attorney_btn').on('click', function() {
      if (count >= maxCount) return alert('لا يمكن إضافة أكثر من 7 وكلاء.');
      count++;
      $('#additional_attorneys').append(`
        <div class="attorney-section pt-6 border-t-2 border-gray-300 mt-6">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-medium text-gray-700">وكيل إضافي ${count}</h3>
            <button type="button" class="remove-attorney text-red-600 hover:text-red-800 px-3 py-1 border border-red-600 rounded text-sm">× حذف</button>
          </div>
          <div class="grid grid-cols-2 gap-6">
            <div class="text-right">
              <label class="block text-base font-medium mb-3">اسم الوكيل</label>
              <input type="text" name="attorney_name_${count}" class="border border-gray-300 p-3 rounded w-full text-right text-sm">
            </div>
            <div class="text-right">
              <label class="block text-base font-medium mb-3">الرقم القومي</label>
              <input type="text" name="attorney_national_id_${count}" maxlength="14" class="border border-gray-300 p-3 rounded w-full text-right text-sm">
            </div>
          </div>
        </div>
      `);
    });

    // حذف وكيل
    $(document).on('click', '.remove-attorney', function() {
      $(this).closest('.attorney-section').remove();
      count--;
    });
  </script>
</body>
</html>
