<?php
// viewer.php - صفحة عرض الملفات STL مع تحسينات لعرض الفكين والتحكم في اللثة والأسنان

// التحقق من وجود معلومات العميل
if (!isset($_GET['client']) || empty($_GET['client'])) {
    die("خطأ: لم يتم تحديد معلومات العميل");
}

$clientFolder = $_GET['client'];
$uploadDir = "uploads/" . $clientFolder . "/";
$jsonFile = $uploadDir . 'info.json';

// التحقق من وجود ملف المعلومات
if (!file_exists($jsonFile)) {
    die("خطأ: لم يتم العثور على معلومات العميل");
}

// قراءة معلومات المجموعة
$groupInfo = json_decode(file_get_contents($jsonFile), true);
$clientName = $groupInfo['clientName'];
$files = $groupInfo['files'];
?>

<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>عرض نماذج STL - <?php echo htmlspecialchars($clientName); ?></title>
    
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    
    <!-- Three.js Libraries -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/STLLoader.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/exporters/STLExporter.js"></script>
    
    <style>
        .loader {
            border: 5px solid #f3f3f3;
            border-top: 5px solid #3498db;
            border-radius: 50%;
            width: 30px;
            height: 30px;
            animation: spin 1s linear infinite;
            display: inline-block;
            vertical-align: middle;
            margin-right: 10px;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .model-controls {
            position: absolute;
            bottom: 10px;
            left: 0;
            right: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            background-color: rgba(255, 255, 255, 0.7);
            padding: 5px;
            border-radius: 10px;
            margin: 0 10px;
        }
        
        .counter-controls {
            display: flex;
            align-items: center;
            margin: 0 15px;
        }
        
        .counter-btn {
            width: 30px;
            height: 30px;
            display: flex;
            align-items: center;
            justify-content: center;
            background-color: #e2e8f0;
            border-radius: 50%;
            cursor: pointer;
        }
        
        .counter-value {
            margin: 0 10px;
            font-weight: bold;
        }
        
        .play-button {
            width: 40px;
            height: 40px;
            background-color: #3498db;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            cursor: pointer;
            margin-left: 15px;
        }
        
        .side-tools {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            display: flex;
            flex-direction: column;
            background-color: rgba(255, 255, 255, 0.7);
            border-radius: 10px;
            padding: 5px;
        }
        
        .tool-btn {
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 5px 0;
            border-radius: 50%;
            cursor: pointer;
            background-color: #f0f4f8;
        }
        
        .parts-panel {
            position: absolute;
            left: 10px;
            top: 10px;
            background-color: rgba(255, 255, 255, 0.8);
            border-radius: 8px;
            padding: 10px;
            max-height: 300px;
            overflow-y: auto;
            width: 200px;
        }
        
        .part-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 5px;
            padding: 5px;
            border-radius: 4px;
            cursor: pointer;
        }
        
        .part-item:hover {
            background-color: #f0f0f0;
        }
        
        .part-item.selected {
            background-color: #e0f0ff;
        }

        .annotation-panel {
            position: absolute;
            left: 220px;
            top: 10px;
            background-color: rgba(255, 255, 255, 0.9);
            border-radius: 8px;
            padding: 10px;
            width: 200px;
            display: none;
        }

        .comment-item {
            background-color: #f9f9f9;
            border-left: 4px solid #3498db;
            padding: 10px;
            margin-bottom: 10px;
            border-radius: 4px;
            animation: fadeIn 0.5s ease-in-out;
        }

        .color-swatch {
            width: 20px;
            height: 20px;
            border-radius: 50%;
            margin-right: 5px;
            cursor: pointer;
        }

        .model-thumbnail {
            background-color: #e5e7eb;
            position: relative;
            overflow: hidden;
        }

        .model-thumbnail canvas {
            width: 100%;
            height: 100%;
        }
    </style>
</head>
<body class="bg-gray-100 min-h-screen">
    <div class="container mx-auto px-4 py-8">
        <div class="bg-white rounded-lg shadow-lg overflow-hidden">
            <div class="p-3 bg-gray-100 border-b flex justify-between items-center">
                <h3 class="font-medium text-lg"><?php echo htmlspecialchars($clientName); ?> - نماذج STL</h3>
                <div class="flex space-x-2">
                    <button id="info-button" class="p-1 rounded hover:bg-gray-200 focus:outline-none">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </button>
                    <button id="export-model" class="p-1 rounded bg-blue-500 text-white hover:bg-blue-600 focus:outline-none ml-2">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                        </svg>
                    </button>
                    <button id="toggle-parts-panel" class="p-1 rounded hover:bg-gray-200 focus:outline-none">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                        </svg>
                    </button>
                </div>
            </div>
            
            <!-- عارض النموذج الرئيسي -->
            <div class="main-model-viewer relative" style="height: 400px;" id="main-viewer">
                <div class="loading-indicator absolute inset-0 flex items-center justify-center bg-white bg-opacity-80 hidden">
                    <div class="loader"></div>
                    <span>جاري التحميل...</span>
                </div>
                
                <!-- لوحة الأجزاء -->
                <div class="parts-panel" id="parts-panel">
                    <h4 class="font-medium mb-2">أجزاء النموذج</h4>
                    <div id="parts-list" class="text-sm"></div>
                </div>
                
                <!-- لوحة الملاحظات (مخفية افتراضيًا) -->
                <div class="annotation-panel" id="annotation-panel">
                    <h4 class="font-medium mb-2">إضافة ملاحظات</h4>
                    <p class="text-sm mb-2">اضغط على النموذج لتحديد مكان الملاحظة</p>
                    <textarea id="annotation-text" class="border rounded p-2 w-full mb-2" placeholder="أضف ملاحظة..."></textarea>
                    <button id="add-text-annotation" class="bg-blue-500 text-white rounded py-1 px-2 mb-2">إضافة نص</button>
                    <div class="flex space-x-2">
                        <button id="add-square-annotation" class="bg-green-500 text-white rounded py-1 px-2">مربع</button>
                        <button id="add-triangle-annotation" class="bg-yellow-500 text-white rounded py-1 px-2">مثلث</button>
                    </div>
                </div>
                
                <!-- أدوات جانبية -->
                <div class="side-tools">
                    <button class="tool-btn" id="toggle-annotation-panel" title="إظهار/إخفاء لوحة الملاحظات">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                    </button>
                    <button class="tool-btn" id="color-first-model" title="تلوين النموذج الأول">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                        </svg>
                    </button>
                    <button class="tool-btn" id="wireframe-toggle" title="عرض الإطار السلكي">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </button>
                    <button class="tool-btn" id="toggle-teeth" title="إظهار/إخفاء الأسنان">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        </svg>
                    </button>
                    <button class="tool-btn" id="toggle-gum" title="إظهار/إخفاء اللثة">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        </svg>
                    </button>
                    <button class="tool-btn" id="toggle-upper-jaw" title="إظهار/إخفاء الفك العلوي">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                        </svg>
                    </button>
                    <button class="tool-btn" id="toggle-lower-jaw" title="إظهار/إخفاء الفك السفلي">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                        </svg>
                    </button>
                    <button class="tool-btn" id="reset-view" title="إعادة ضبط العرض">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                        </svg>
                    </button>
                    <button class="tool-btn" id="show-all-parts" title="إظهار جميع الأجزاء">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        </svg>
                    </button>
                </div>

                <!-- أدوات التصوير والزوم -->
                <div class="zoom-control absolute bottom-20 left-4 bg-white rounded-lg p-1 shadow-md">
                    <button id="zoom-in" class="p-1 hover:bg-gray-200 rounded" title="تكبير">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
                        </svg>
                    </button>
                    <button id="zoom-out" class="p-1 hover:bg-gray-200 rounded" title="تصغير">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM13 10H7" />
                        </svg>
                    </button>
                </div>

                <button class="screenshot-btn absolute top-4 right-4 bg-white rounded-lg p-2 shadow-md flex items-center" title="التقاط صورة">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <span>التقط صورة</span>
                </button>

                <!-- خيارات الألوان -->
                <div class="color-options absolute top-4 left-4 bg-white rounded-lg p-1 shadow-md flex">
                    <button class="color-btn w-6 h-6 rounded-full m-1" style="background-color: #FF0000;" data-color="0xFF0000" title="أحمر"></button>
                    <button class="color-btn w-6 h-6 rounded-full m-1" style="background-color: #00FF00;" data-color="0x00FF00" title="أخضر"></button>
                    <button class="color-btn w-6 h-6 rounded-full m-1" style="background-color: #0000FF;" data-color="0x0000FF" title="أزرق"></button>
                    <button class="color-btn w-6 h-6 rounded-full m-1" style="background-color: #FFFF00;" data-color="0xFFFF00" title="أصفر"></button>
                    <button class="color-btn w-6 h-6 rounded-full m-1" style="background-color: #FFFFFF;" data-color="0xFFFFFF" title="أبيض"></button>
                </div>
                
                <!-- أدوات التحكم السفلية -->
                <div class="model-controls">
                    <div class="counter-controls">
                        <div class="counter-btn decrease-model" title="النموذج السابق">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clip-rule="evenodd" />
                            </svg>
                        </div>
                        <div class="counter-value model-counter">0</div>
                        <div class="counter-btn increase-model" title="النموذج التالي">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd" />
                            </svg>
                        </div>
                    </div>
                    
                    <div class="counter-controls">
                        <div class="counter-btn" id="upper-row" title="الصف العلوي">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                            </svg>
                        </div>
                        <div class="counter-btn" id="lower-row" title="الصف السفلي">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                            </svg>
                        </div>
                        <div class="counter-btn" id="both-rows" title="كلا الصفين">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7M19 9l-7 7-7-7" />
                            </svg>
                        </div>
                    </div>
                    
                    <div class="play-button" id="auto-play" title="تشغيل تلقائي">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </div>
                </div>
            </div>
            
            <!-- معلومات النموذج -->
            <div id="model-info" class="p-4 bg-gray-50 border-t hidden">
                <h4 class="font-medium mb-2">معلومات النموذج</h4>
                <div id="model-details" class="text-sm"></div>
            </div>
        </div>
        
        <!-- قائمة النماذج -->
        <div class="mt-6">
            <h3 class="font-medium mb-3">كل النماذج المتاحة</h3>
            <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-4" id="models-grid">
                <?php foreach ($files as $index => $file): ?>
                <div class="model-item bg-white rounded-lg shadow-md overflow-hidden cursor-pointer" data-index="<?php echo $index; ?>" data-path="<?php echo htmlspecialchars($file['path']); ?>">
                    <div class="model-thumbnail bg-gray-200" style="height: 150px;"></div>
                    <div class="p-3">
                        <h4 class="font-medium truncate"><?php echo htmlspecialchars($file['name']); ?></h4>
                    </div>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
        
        <!-- قسم التعليقات -->
        <div class="mt-6 bg-white rounded-lg shadow-lg p-4">
            <h3 class="font-medium mb-3">التعليقات</h3>
            <div id="comments-list" class="mb-4">
                <div class="text-gray-500 italic">لا توجد تعليقات حتى الآن</div>
            </div>
            <form id="comment-form" class="flex flex-col">
                <textarea id="comment-text" class="border rounded p-2 mb-2" placeholder="أضف تعليقك..."></textarea>
                <button type="submit" class="bg-blue-500 text-white rounded py-2 px-4 self-end hover:bg-blue-600">إرسال</button>
            </form>
        </div>
    </div>

    <script>
      document.addEventListener('DOMContentLoaded', () => {
    // تخزين جميع النماذج من السيرفر
    const allModels = <?php echo json_encode($files, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT); ?>;
    // متغيرات عالمية لـ Three.js
    let scene, camera, renderer, controls;
    let modelsGroup = new THREE.Group();
    let currentModelIndex = 1; // بداية من 1
    let previousModelIndex = 0; // بداية من 0
    let displayMode = 'both';
    const JawTypes = {
        UPPER: 'upper_jaw',
        LOWER: 'lower_jaw',
        UNKNOWN: 'unknown_jaw'
    };
    const ComponentTypes = {
        TEETH: 'teeth',
        GUM: 'gum'
    };
    let jawMaterials = {};
    let modelColors = new Map(); // تخزين ألوان كل نموذج
    let displayedModelIndices = new Set(); // تتبع النماذج المعروضة
    let visibilityStates = {
        [JawTypes.UPPER]: { [ComponentTypes.TEETH]: true, [ComponentTypes.GUM]: true },
        [JawTypes.LOWER]: { [ComponentTypes.TEETH]: true, [ComponentTypes.GUM]: true },
        [JawTypes.UNKNOWN]: { [ComponentTypes.TEETH]: true, [ComponentTypes.GUM]: true }
    };
    let upperJawMesh = null;
    let lowerJawMesh = null;
    let isPlaying = false;
    let playInterval = null;
    let annotations = [];
    let isWireframe = false;
    let preloadedModels = new Map();
    let time = 0;
    const mainContainer = document.getElementById('main-viewer');
    const loadingIndicator = document.querySelector('.loading-indicator');

    // إنشاء المواد للثة والأسنان مع الألوان من الكود الأول
    function createJawMaterials(modelIndex) {
        const modelData = preloadedModels.get(modelIndex);
        let originalColors = { gum: 0xA52A2A, teeth: 0xFFF8E7 }; // الألوان الافتراضية

        if (modelData && modelData.geometry.attributes.color) {
            const colors = modelData.geometry.attributes.color.array;
            originalColors.gum = colors.length > 0 ? new THREE.Color(colors[0], colors[1], colors[2]).getHex() : 0xA52A2A;
            originalColors.teeth = colors.length > 3 ? new THREE.Color(colors[3], colors[4], colors[5]).getHex() : 0xFFF8E7;
        }

        const currentColors = modelColors.get(modelIndex) || originalColors;
        jawMaterials[modelIndex] = {
            gum: new THREE.MeshPhysicalMaterial({
                color: currentColors.gum,
                metalness: 0.0,
                roughness: 0.5,
                clearcoat: 0.3,
                transparent: true,
                opacity: 0.9,
                side: THREE.DoubleSide,
                emissive: currentColors.gum === 0xA52A2A ? 0x4A1010 : currentColors.gum,
                emissiveIntensity: 0.2,
                reflectivity: 0.3,
                polygonOffset: true,
                polygonOffsetFactor: 1,
                polygonOffsetUnits: 1,
                depthWrite: true
            }),
            teeth: new THREE.MeshPhysicalMaterial({
                color: currentColors.teeth,
                metalness: 0.0,
                roughness: 0.01,
                clearcoat: 1.8,
                transparent: false,
                side: THREE.DoubleSide,
                emissive: currentColors.teeth === 0xFFF8E7 ? 0xE8E1D1 : currentColors.teeth,
                emissiveIntensity: 0.1,
                reflectivity: 1.2,
                depthWrite: true,
                polygonOffset: false
            })
        };
        return jawMaterials[modelIndex];
    }

    // تحديث الألوان لنموذج معين
    function updateModelColors(modelIndex, newColors) {
        modelColors.set(modelIndex, newColors);
        const materials = createJawMaterials(modelIndex);
        if (upperJawMesh && preloadedModels.get(modelIndex)?.jawType === JawTypes.UPPER) {
            upperJawMesh.material = [materials.gum, materials.teeth];
        }
        if (lowerJawMesh && preloadedModels.get(modelIndex)?.jawType === JawTypes.LOWER) {
            lowerJawMesh.material = [materials.gum, materials.teeth];
        }
        renderer.render(scene, camera);
    }

    // تحليل نوع الفك بناءً على الهندسة واسم الملف
    function analyzeComponent(geometry, fileName) {
        geometry.computeBoundingBox();
        const center = new THREE.Vector3();
        geometry.boundingBox.getCenter(center);
        const isUpperFromName = fileName.toLowerCase().includes('upper');
        const isLowerFromName = fileName.toLowerCase().includes('lower');
        let jawType = JawTypes.UNKNOWN;
        if (isUpperFromName) {
            jawType = JawTypes.UPPER;
        } else if (isLowerFromName) {
            jawType = JawTypes.LOWER;
        } else {
            if (center.y > 0.1) {
                jawType = JawTypes.UPPER;
            } else if (center.y < -0.1) {
                jawType = JawTypes.LOWER;
            }
        }
        return { jawType };
    }

    // تبسيط الهندسة لتقليل عدد المثلثات
    function simplifyGeometry(geometry, targetReduction = 0.5) {
        if (!geometry.index) {
            console.warn("Geometry is not indexed, skipping simplification.");
            return geometry;
        }
        const positions = geometry.attributes.position.array;
        const indexArray = geometry.index.array;
        const numTriangles = indexArray.length / 3;
        const triangleAreas = new Array(numTriangles);
        for (let i = 0; i < numTriangles; i++) {
            const v0 = indexArray[i * 3] * 3;
            const v1 = indexArray[i * 3 + 1] * 3;
            const v2 = indexArray[i * 3 + 2] * 3;
            const triangle = new THREE.Triangle(
                new THREE.Vector3(positions[v0], positions[v0 + 1], positions[v0 + 2]),
                new THREE.Vector3(positions[v1], positions[v1 + 1], positions[v1 + 2]),
                new THREE.Vector3(positions[v2], positions[v2 + 1], positions[v2 + 2])
            );
            triangleAreas[i] = { index: i, area: triangle.getArea() };
        }
        triangleAreas.sort((a, b) => a.area - b.area);
        const numToRemove = Math.floor(numTriangles * targetReduction);
        const trianglesToRemove = new Set(triangleAreas.slice(0, numToRemove).map(item => item.index));
        const newIndices = [];
        for (let i = 0; i < numTriangles; i++) {
            if (!trianglesToRemove.has(i)) {
                newIndices.push(
                    indexArray[i * 3],
                    indexArray[i * 3 + 1],
                    indexArray[i * 3 + 2]
                );
            }
        }
        if (newIndices.length === 0) {
            console.warn("All triangles were removed during simplification, reverting to original geometry.");
            return geometry;
        }
        geometry.setIndex(newIndices);
        geometry.computeVertexNormals();
        return geometry;
    }

    // تقسيم الهندسة إلى أسنان ولثة مع تحسينات
    function segmentJawGeometry(geometry, jawType) {
        if (!geometry || !geometry.attributes || !geometry.attributes.position || !geometry.attributes.normal) {
            console.error("الهندسة غير صالحة للتقسيم.");
            return;
        }
        const positions = geometry.attributes.position.array;
        const normals = geometry.attributes.normal.array;
        const vertexCount = geometry.attributes.position.count;
        const indexArray = geometry.index ? geometry.index.array : null;
        const isIndexed = indexArray !== null;
        const numTriangles = isIndexed ? indexArray.length / 3 : vertexCount / 3;
        
        if (numTriangles === 0) {
            console.warn("تحذير: لا يوجد مثلثات في الهندسة.");
            geometry.clearGroups();
            return;
        }
        
        geometry.computeBoundingBox();
        const boundingBox = geometry.boundingBox;
        const minY = boundingBox.min.y;
        const maxY = boundingBox.max.y;
        const height = maxY - minY;
        
        if (height <= 1e-6) {
            console.warn("تحذير: ارتفاع صندوق الإحاطة صغير جداً.");
            geometry.clearGroups();
            if (numTriangles > 0) {
                const totalBufferElements = isIndexed ? indexArray.length : vertexCount * 3;
                geometry.addGroup(0, totalBufferElements, 0);
            }
            return;
        }
        
        const gridSize = 250;
        const grid = new Array(gridSize).fill(0).map(() =>
            new Array(gridSize).fill(0).map(() =>
                new Array(gridSize).fill(0)
            )
        );
        
        const gridBounds = {
            x: boundingBox.max.x - boundingBox.min.x,
            y: boundingBox.max.y - boundingBox.min.y,
            z: boundingBox.max.z - boundingBox.min.z
        };
        
        gridBounds.x = gridBounds.x <= 0 ? 1 : gridBounds.x;
        gridBounds.y = gridBounds.y <= 0 ? 1 : gridBounds.y;
        gridBounds.z = gridBounds.z <= 0 ? 1 : gridBounds.z;
        
        for (let i = 0; i < numTriangles; i++) {
            const v0 = isIndexed ? indexArray[i * 3] : i * 3;
            const v1 = isIndexed ? indexArray[i * 3 + 1] : i * 3 + 1;
            const v2 = isIndexed ? indexArray[i * 3 + 2] : i * 3 + 2;
            
            const triCenterY = (positions[v0 * 3 + 1] + positions[v1 * 3 + 1] + positions[v2 * 3 + 1]) / 3;
            const triCenterX = (positions[v0 * 3] + positions[v1 * 3] + positions[v2 * 3]) / 3;
            const triCenterZ = (positions[v0 * 3 + 2] + positions[v1 * 3 + 2] + positions[v2 * 3 + 2]) / 3;
            
            const nx = Math.floor((triCenterX - boundingBox.min.x) / gridBounds.x * (gridSize - 1));
            const ny = Math.floor((triCenterY - boundingBox.min.y) / gridBounds.y * (gridSize - 1));
            const nz = Math.floor((triCenterZ - boundingBox.min.z) / gridBounds.z * (gridSize - 1));
            
            if (nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize && nz >= 0 && nz < gridSize) {
                grid[nx][ny][nz]++;
            }
        }
        
        const totalArea = calculateSurfaceArea(geometry);
        const averageTriangleArea = numTriangles > 0 ? totalArea / numTriangles : 0;
        
        const relativeHeightTeethZoneStart = (jawType === JawTypes.UPPER) ? 0.60 : 0.40; // Stricter for upper jaw
        const relativeHeightTeethZoneEnd = (jawType === JawTypes.UPPER) ? 1.00 : 0.80;   // Ensure only top is teeth
        const yRangeThresholdFlat = height * 0.002;
        const normalYTeethCriteria = (n) => Math.abs(n.y) > 0.60; // Stricter for teeth
        const normalYGumCriteria = (n) => Math.abs(n.y) < 0.15;   // Stricter for gums
        const curvatureThresholdHigh = 0.35;                      // Stricter for teeth
        const curvatureThresholdLow = 0.0006;                     // Stricter for gums
        const densityThresholdHigh = 7.0;                         // Increased for teeth
        const densityThresholdLow = 0.04;                         // Decreased for gums
        const areaRatioTeethSmall = 0.18;                         // Smaller triangles for teeth
        const areaRatioGumLarge = 2.7;                            // Larger triangles for gums
        
        const initialClassification = new Array(numTriangles);
        
        for (let i = 0; i < numTriangles; i++) {
            const v0 = isIndexed ? indexArray[i * 3] : i * 3;
            const v1 = isIndexed ? indexArray[i * 3 + 1] : i * 3 + 1;
            const v2 = isIndexed ? indexArray[i * 3 + 2] : i * 3 + 2;
            
            const triCenter = new THREE.Vector3(
                (positions[v0 * 3] + positions[v1 * 3] + positions[v2 * 3]) / 3,
                (positions[v0 * 3 + 1] + positions[v1 * 3 + 1] + positions[v2 * 3 + 1]) / 3,
                (positions[v0 * 3 + 2] + positions[v1 * 3 + 2] + positions[v2 * 3 + 2]) / 3
            );
            
            const relativeHeight = (triCenter.y - minY) / height;
            
            const normalV0 = new THREE.Vector3(normals[v0*3], normals[v0*3+1], normals[v0*3+2]);
            const normalV1 = new THREE.Vector3(normals[v1*3], normals[v1*3+1], normals[v1*3+2]);
            const normalV2 = new THREE.Vector3(normals[v2*3], normals[v2*3+1], normals[v2*3+2]);
            
            const triangleNormal = normalV0.clone().add(normalV1).add(normalV2).normalize();
            
            const area = new THREE.Triangle(
                new THREE.Vector3(positions[v0*3], positions[v0*3+1], positions[v0*3+2]),
                new THREE.Vector3(positions[v1*3], positions[v1*3+1], positions[v1*3+2]),
                new THREE.Vector3(positions[v2*3], positions[v2*3+1], positions[v2*3+2])
            ).getArea();
            
            const areaRatio = averageTriangleArea > 1e-6 ? area / averageTriangleArea : 1;
            
            const yMinTri = Math.min(positions[v0 * 3 + 1], positions[v1 * 3 + 1], positions[v2 * 3 + 1]);
            const yMaxTri = Math.max(positions[v0 * 3 + 1], positions[v1 * 3 + 1], positions[v2 * 3 + 1]);
            const yRangeTri = yMaxTri - yMinTri;
            
            const curvature = normalV0.distanceTo(normalV1) + normalV1.distanceTo(normalV2) + normalV2.distanceTo(normalV0);
            
            const nx = Math.floor((triCenter.x - boundingBox.min.x) / gridBounds.x * (gridSize - 1));
            const ny = Math.floor((triCenter.y - boundingBox.min.y) / gridBounds.y * (gridSize - 1));
            const nz = Math.floor((triCenter.z - boundingBox.min.z) / gridBounds.z * (gridSize - 1));
            
            let density = 0;
            if (nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize && nz >= 0 && nz < gridSize) {
                density = grid[nx][ny][nz];
            }
            
            let isTeeth = false;
            
            // Hard rule for upper jaw: anything below 35% height is gum
            if (jawType === JawTypes.UPPER && relativeHeight < 0.35) {
                isTeeth = false;
            } else {
                const strongTeethIndicators = (
                    normalYTeethCriteria(triangleNormal) && 
                    curvature > curvatureThresholdHigh &&
                    relativeHeight >= relativeHeightTeethZoneStart &&
                    relativeHeight <= relativeHeightTeethZoneEnd
                ) || (
                    density > densityThresholdHigh && 
                    areaRatio < areaRatioTeethSmall &&
                    relativeHeight >= relativeHeightTeethZoneStart
                );
                
                const strongGumIndicators = (
                    normalYGumCriteria(triangleNormal) && 
                    yRangeTri < yRangeThresholdFlat && 
                    curvature < curvatureThresholdLow
                ) || (
                    relativeHeight < relativeHeightTeethZoneStart && 
                    normalYGumCriteria(triangleNormal) && 
                    density < densityThresholdHigh
                ) || (
                    areaRatio > areaRatioGumLarge && 
                    yRangeTri < yRangeThresholdFlat * 2
                );
                
                if (strongTeethIndicators && !strongGumIndicators) {
                    isTeeth = true;
                } else if (strongGumIndicators && !strongTeethIndicators) {
                    isTeeth = false;
                } else if (strongTeethIndicators && strongGumIndicators) {
                    if (curvature > curvatureThresholdHigh * 1.5 && relativeHeight > relativeHeightTeethZoneStart) {
                        isTeeth = true;
                    } else {
                        isTeeth = false;
                    }
                } else {
                    const weakTeethIndicators = (
                        relativeHeight >= relativeHeightTeethZoneStart * 0.9 && 
                        relativeHeight <= relativeHeightTeethZoneEnd && 
                        Math.abs(triangleNormal.y) > 0.50 
                    ) || (
                        curvature > curvatureThresholdLow * 1.5 && 
                        yRangeTri > yRangeThresholdFlat 
                    ) || (
                        density > densityThresholdLow * 1.5 
                    );
                    
                    isTeeth = weakTeethIndicators;
                }
            }
            
            // Additional rule for sides of upper jaw (based on low curvature and near-horizontal normals)
            if (jawType === JawTypes.UPPER && curvature < curvatureThresholdLow * 1.2 && Math.abs(triangleNormal.y) < 0.20) {
                isTeeth = false;
            }
            
            if (jawType === JawTypes.LOWER && relativeHeight > 0.85) {
                isTeeth = false;
            }
            
            initialClassification[i] = isTeeth;
        }
        
        let currentClassification = [...initialClassification];
        currentClassification = refineTeethGumBoundary(geometry, currentClassification, jawType);
        currentClassification = postProcessClassification(geometry, currentClassification, jawType);
        
        const teethCount = currentClassification.filter(isTeeth => isTeeth).length;
        const gumCount = numTriangles - teethCount;
        console.log(`Classification: ${teethCount} teeth triangles, ${gumCount} gum triangles`);
        
        geometry.clearGroups();
        
        if (numTriangles > 0) {
            const gumIndices = [];
            const teethIndices = [];
            
            for (let i = 0; i < numTriangles; i++) {
                if (!currentClassification[i]) {
                    if (isIndexed) {
                        gumIndices.push(
                            indexArray[i * 3],
                            indexArray[i * 3 + 1],
                            indexArray[i * 3 + 2]
                        );
                    } else {
                        gumIndices.push(i * 3, i * 3 + 1, i * 3 + 2);
                    }
                } else {
                    if (isIndexed) {
                        teethIndices.push(
                            indexArray[i * 3],
                            indexArray[i * 3 + 1],
                            indexArray[i * 3 + 2]
                        );
                    } else {
                        teethIndices.push(i * 3, i * 3 + 1, i * 3 + 2);
                    }
                }
            }
            
            if (gumIndices.length > 0) {
                geometry.addGroup(0, gumIndices.length, 0);
            }
            
            if (teethIndices.length > 0) {
                geometry.addGroup(gumIndices.length, teethIndices.length, 1);
            }
            
            const newIndices = [...gumIndices, ...teethIndices];
            
            if (isIndexed) {
                geometry.setIndex(newIndices);
            } else {
                console.warn("الهندسة غير مفهرسة، لا يمكن إعادة ترتيب المؤشرات.");
            }
            
            if (geometry.groups.length === 0 || 
                !geometry.groups.some(group => group.materialIndex === 0) || 
                !geometry.groups.some(group => group.materialIndex === 1)) {
                
                console.warn("No proper groups detected, creating default groups.");
                geometry.clearGroups();
                
                const halfPoint = Math.floor(newIndices.length / 2);
                geometry.addGroup(0, halfPoint, 0);
                geometry.addGroup(halfPoint, newIndices.length - halfPoint, 1);
            }
        }
        
        console.log(`تم تقسيم الهندسة بنجاح إلى ${geometry.groups.length} مجموعات.`);
        console.log("Groups:", geometry.groups);
        
        geometry.computeVertexNormals();
    }

    // حساب مساحة السطح
    function calculateSurfaceArea(geometry) {
        const positions = geometry.attributes.position.array;
        const indexArray = geometry.index ? geometry.index.array : null;
        const isIndexed = indexArray !== null;
        const numTriangles = isIndexed ? indexArray.length / 3 : geometry.attributes.position.count / 3;
        
        let area = 0;
        for (let i = 0; i < numTriangles; i++) {
            const v0 = isIndexed ? indexArray[i * 3] : i * 3;
            const v1 = isIndexed ? indexArray[i * 3 + 1] : i * 3 + 1;
            const v2 = isIndexed ? indexArray[i * 3 + 2] : i * 3 + 2;
            
            const vA = new THREE.Vector3(positions[v0*3], positions[v0*3+1], positions[v0*3+2]);
            const vB = new THREE.Vector3(positions[v1*3], positions[v1*3+1], positions[v1*3+2]);
            const vC = new THREE.Vector3(positions[v2*3], positions[v2*3+1], positions[v2*3+2]);
            
            area += new THREE.Triangle(vA, vB, vC).getArea();
        }
        
        return area;
    }

    // بناء قائمة التجاور للمثلثات
    function buildTriangleAdjacency(geometry) {
        const positions = geometry.attributes.position.array;
        const indexArray = geometry.index ? geometry.index.array : null;
        const isIndexed = indexArray !== null;
        const numTriangles = isIndexed ? indexArray.length / 3 : geometry.attributes.position.count / 3;
        
        const edgeMap = new Map();
        
        for (let i = 0; i < numTriangles; i++) {
            const v0 = isIndexed ? indexArray[i * 3] : i * 3;
            const v1 = isIndexed ? indexArray[i * 3 + 1] : i * 3 + 1;
            const v2 = isIndexed ? indexArray[i * 3 + 2] : i * 3 + 2;
            
            const edges = [
                [Math.min(v0, v1), Math.max(v0, v1)],
                [Math.min(v1, v2), Math.max(v1, v2)],
                [Math.min(v2, v0), Math.max(v2, v0)]
            ];
            
            for (const edge of edges) {
                const key = `${edge[0]}-${edge[1]}`;
                if (!edgeMap.has(key)) {
                    edgeMap.set(key, new Set());
                }
                edgeMap.get(key).add(i);
            }
        }
        
        const triangleAdjacency = new Map();
        for (let i = 0; i < numTriangles; i++) {
            triangleAdjacency.set(i, new Set());
        }
        
        for (const [key, triangles] of edgeMap.entries()) {
            if (triangles.size === 2) {
                const [tri1, tri2] = Array.from(triangles);
                triangleAdjacency.get(tri1).add(tri2);
                triangleAdjacency.get(tri2).add(tri1);
            }
        }
        
        return triangleAdjacency;
    }

    // تحسين حدود الأسنان واللثة مع تحسينات
    function refineTeethGumBoundary(geometry, classification, jawType) {
        const triangleAdjacency = buildTriangleAdjacency(geometry);
        const positions = geometry.attributes.position.array;
        const normals = geometry.attributes.normal.array;
        const indexArray = geometry.index ? geometry.index.array : null;
        const isIndexed = indexArray !== null;
        const numTriangles = isIndexed ? indexArray.length / 3 : positions.length / 9;
        
        geometry.computeBoundingBox();
        const boundingBox = geometry.boundingBox;
        const minY = boundingBox.min.y;
        const maxY = boundingBox.max.y;
        const height = maxY - minY;
        
        const boundaryTriangles = new Set();
        for (let i = 0; i < numTriangles; i++) {
            const neighbors = triangleAdjacency.get(i) || new Set();
            for (const neighbor of neighbors) {
                if (classification[i] !== classification[neighbor]) {
                    boundaryTriangles.add(i);
                    break;
                }
            }
        }
        
        const safetyRegion = new Set();
        for (const triangleIndex of boundaryTriangles) {
            const neighbors = triangleAdjacency.get(triangleIndex) || new Set();
            for (const neighbor of neighbors) {
                safetyRegion.add(neighbor);
            }
        }
        
        let refinedClassification = [...classification];
        const iterations = 200; // Increased for better refinement
        
        for (let iter = 0; iter < iterations; iter++) {
            const newClassification = [...refinedClassification];
            
            for (const triangleIndex of boundaryTriangles) {
                const v0 = isIndexed ? indexArray[triangleIndex * 3] : triangleIndex * 3;
                const v1 = isIndexed ? indexArray[triangleIndex * 3 + 1] : triangleIndex * 3 + 1;
                const v2 = isIndexed ? indexArray[triangleIndex * 3 + 2] : triangleIndex * 3 + 2;
                
                const triCenter = new THREE.Vector3(
                    (positions[v0 * 3] + positions[v1 * 3] + positions[v2 * 3]) / 3,
                    (positions[v0 * 3 + 1] + positions[v1 * 3 + 1] + positions[v2 * 3 + 1]) / 3,
                    (positions[v0 * 3 + 2] + positions[v1 * 3 + 2] + positions[v2 * 3 + 2]) / 3
                );
                
                const relativeHeight = (triCenter.y - minY) / height;
                
                const normalV0 = new THREE.Vector3(normals[v0*3], normals[v0*3+1], normals[v0*3+2]);
                const normalV1 = new THREE.Vector3(normals[v1*3], normals[v1*3+1], normals[v1*3+2]);
                const normalV2 = new THREE.Vector3(normals[v2*3], normals[v2*3+1], normals[v2*3+2]);
                
                const triangleNormal = normalV0.clone().add(normalV1).add(normalV2).normalize();
                const curvature = normalV0.distanceTo(normalV1) + normalV1.distanceTo(normalV2) + normalV2.distanceTo(normalV0);
                
                const neighbors = triangleAdjacency.get(triangleIndex) || new Set();
                let teethNeighbors = 0;
                let gumNeighbors = 0;
                
                for (const neighbor of neighbors) {
                    if (refinedClassification[neighbor]) {
                        teethNeighbors++;
                    } else {
                        gumNeighbors++;
                    }
                }
                
                const totalNeighbors = neighbors.size;
                const teethRatio = totalNeighbors > 0 ? teethNeighbors / totalNeighbors : 0;
                
                const jawSpecificHeightFactor = (jawType === JawTypes.UPPER) ? 0.60 : 0.40;
                
                const shouldBeTeeth = (
                    (relativeHeight > jawSpecificHeightFactor && Math.abs(triangleNormal.y) > 0.50) &&
                    (curvature > 0.30 && teethRatio > 0.7)
                );
                
                const shouldBeGum = (
                    (relativeHeight < jawSpecificHeightFactor - 0.05 || Math.abs(triangleNormal.y) < 0.15) ||
                    (curvature < 0.0008 && teethRatio < 0.05) ||
                    (teethRatio < 0.05)
                );
                
                // Enforce gums for sides and base of upper jaw
                if (jawType === JawTypes.UPPER) {
                    if (relativeHeight < 0.35 || (curvature < 0.0008 && Math.abs(triangleNormal.y) < 0.20)) {
                        newClassification[triangleIndex] = false;
                        continue;
                    }
                }
                
                if (shouldBeTeeth && !shouldBeGum) {
                    newClassification[triangleIndex] = true;
                } else if (shouldBeGum && !shouldBeTeeth) {
                    newClassification[triangleIndex] = false;
                } else if (teethRatio > 0.80) {
                    newClassification[triangleIndex] = true;
                } else if (teethRatio < 0.05) {
                    newClassification[triangleIndex] = false;
                } else {
                    newClassification[triangleIndex] = relativeHeight > jawSpecificHeightFactor;
                }
            }
            
            refinedClassification = newClassification;
            
            if (iter > iterations - 50) {
                for (const triangleIndex of safetyRegion) {
                    if (boundaryTriangles.has(triangleIndex)) continue;
                    
                    const neighbors = triangleAdjacency.get(triangleIndex) || new Set();
                    let teethNeighbors = 0;
                    let gumNeighbors = 0;
                    
                    for (const neighbor of neighbors) {
                        if (refinedClassification[neighbor]) {
                            teethNeighbors++;
                        } else {
                            gumNeighbors++;
                        }
                    }
                    
                    const totalNeighbors = neighbors.size;
                    
                    if (totalNeighbors > 0) {
                        if (teethNeighbors > gumNeighbors * 2.5) {
                            refinedClassification[triangleIndex] = true;
                        } else if (gumNeighbors > teethNeighbors * 2.5) {
                            refinedClassification[triangleIndex] = false;
                        }
                    }
                }
            }
        }
        
        for (let iter = 0; iter < 20; iter++) { // Increased smoothing iterations
            const smoothedClassification = [...refinedClassification];
            
            for (const triangleIndex of boundaryTriangles) {
                const neighbors = triangleAdjacency.get(triangleIndex) || new Set();
                let teethCount = 0;
                let gumCount = 0;
                
                for (const neighbor of neighbors) {
                    if (refinedClassification[neighbor]) {
                        teethCount++;
                    } else {
                        gumCount++;
                    }
                }
                
                if (teethCount > gumCount * 2.0) {
                    smoothedClassification[triangleIndex] = true;
                } else if (gumCount > teethCount * 2.0) {
                    smoothedClassification[triangleIndex] = false;
                }
            }
            
            refinedClassification = smoothedClassification;
        }
        
        return refinedClassification;
    }

    // معالجة نهائية للتصنيف مع تحسينات
    function postProcessClassification(geometry, classification, jawType) {
        const triangleAdjacency = buildTriangleAdjacency(geometry);
        const positions = geometry.attributes.position.array;
        const normals = geometry.attributes.normal.array;
        const indexArray = geometry.index ? geometry.index.array : null;
        const isIndexed = indexArray !== null;
        const numTriangles = classification.length;
        let updatedClassification = [...classification];
        
        // Ensure base and sides of upper jaw are gums
        if (jawType === JawTypes.UPPER) {
            for (let i = 0; i < numTriangles; i++) {
                const v0 = isIndexed ? indexArray[i * 3] : i * 3;
                const v1 = isIndexed ? indexArray[i * 3 + 1] : i * 3 + 1;
                const v2 = isIndexed ? indexArray[i * 3 + 2] : i * 3 + 2;
                
                const triCenter = new THREE.Vector3(
                    (positions[v0 * 3] + positions[v1 * 3] + positions[v2 * 3]) / 3,
                    (positions[v0 * 3 + 1] + positions[v1 * 3 + 1] + positions[v2 * 3 + 1]) / 3,
                    (positions[v0 * 3 + 2] + positions[v1 * 3 + 2] + positions[v2 * 3 + 2]) / 3
                );
                
                const relativeHeight = (triCenter.y - minY) / height;
                
                const normalV0 = new THREE.Vector3(normals[v0*3], normals[v0*3+1], normals[v0*3+2]);
                const normalV1 = new THREE.Vector3(normals[v1*3], normals[v1*3+1], normals[v1*3+2]);
                const normalV2 = new THREE.Vector3(normals[v2*3], normals[v2*3+1], normals[v2*3+2]);
                
                const triangleNormal = normalV0.clone().add(normalV1).add(normalV2).normalize();
                const curvature = normalV0.distanceTo(normalV1) + normalV1.distanceTo(normalV2) + normalV2.distanceTo(normalV0);
                
                // Force base (below 35% height) and sides to be gum
                if (relativeHeight < 0.35 || (relativeHeight < 0.40 && Math.abs(triangleNormal.y) < 0.20)) {
                    updatedClassification[i] = false;
                }
                
                // Check neighbors to enforce gum if surrounded by gum
                const neighbors = triangleAdjacency.get(i) || new Set();
                let gumNeighbors = 0;
                let totalNeighbors = neighbors.size;
                
                for (const neighbor of neighbors) {
                    if (!updatedClassification[neighbor]) {
                        gumNeighbors++;
                    }
                }
                
                if (totalNeighbors > 0 && gumNeighbors / totalNeighbors > 0.80 && relativeHeight < 0.40) {
                    updatedClassification[i] = false;
                }
            }
        }
        
        for (let iter = 0; iter < 20; iter++) { // Increased iterations for stability
            const newClassification = [...updatedClassification];
            
            for (let i = 0; i < numTriangles; i++) {
                const neighbors = triangleAdjacency.get(i) || new Set();
                let teethNeighbors = 0;
                let gumNeighbors = 0;
                
                for (const neighbor of neighbors) {
                    if (updatedClassification[neighbor]) {
                        teethNeighbors++;
                    } else {
                        gumNeighbors++;
                    }
                }
                
                const totalNeighbors = neighbors.size;
                
                if (!updatedClassification[i] && totalNeighbors > 0 && teethNeighbors >= totalNeighbors * 0.90) {
                    newClassification[i] = true;
                }
                
                if (updatedClassification[i] && totalNeighbors > 0 && gumNeighbors >= totalNeighbors * 0.90) {
                    newClassification[i] = false;
                }
            }
            
            updatedClassification = newClassification;
        }
        
        return updatedClassification;
    }

    // تحسين موضع النموذج لضمان العرض المتطابق مع زيادة المسافة
    function optimizeModelPosition(mesh, geometry, jawType) {
        if (!geometry || !geometry.boundingBox) {
            console.warn("Cannot optimize position: Geometry or bounding box missing.");
            return;
        }
        
        const boundingBox = geometry.boundingBox;
        const center = new THREE.Vector3();
        boundingBox.getCenter(center);
        
        // محاذاة النموذج إلى المركز
        mesh.position.set(-center.x, 0, -center.z);
        
        const size = boundingBox.getSize(new THREE.Vector3());
        const maxDim = Math.max(size.x, size.y, size.z);
        const scale = maxDim > 1e-6 ? 10 / maxDim : 1;
        mesh.scale.set(scale, scale, scale);
        
        // ضبط تدوير وموضع الفكين مع زيادة المسافة
        if (jawType === JawTypes.UPPER) {
            // الفك العلوي: الأسنان لأسفل
            mesh.rotation.set(Math.PI / 2, 0, Math.PI);
            mesh.position.y = 12 * scale;
        } else if (jawType === JawTypes.LOWER) {
            // الفك السفلي: الأسنان لأسفل
            mesh.rotation.set(-Math.PI / 2, 0, 0);
            mesh.position.y = -2 * scale;
        } else {
            // الفك غير معروف: توجيه افتراضي
            mesh.rotation.set(Math.PI / 2, 0, Math.PI);
            mesh.position.y = 0;
        }
    }

    // إنشاء صورة مصغرة للنموذج
    function createThumbnail(thumbnailElement, modelPath) {
        const width = 200;
        const height = 150;
        
        const scene = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 1000);
        camera.position.set(0, 0, 15);
        
        const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
        renderer.setSize(width, height);
        thumbnailElement.appendChild(renderer.domElement);
        
        const ambientLight = new THREE.AmbientLight(0xFFFFFF, 0.5);
        scene.add(ambientLight);
        const directionalLight = new THREE.DirectionalLight(0xFFFFFF, 0.5);
        directionalLight.position.set(5, 5, 5);
        scene.add(directionalLight);
        
        const loader = new THREE.STLLoader();
        loader.load(modelPath, (geometry) => {
            const material = new THREE.MeshStandardMaterial({ color: 0xAAAAAA });
            const mesh = new THREE.Mesh(geometry, material);
            scene.add(mesh);
            
            geometry.computeBoundingBox();
            const center = new THREE.Vector3();
            geometry.boundingBox.getCenter(center);
            mesh.position.set(-center.x, -center.y, -center.z);
            
            const size = geometry.boundingBox.getSize(new THREE.Vector3());
            const maxDim = Math.max(size.x, size.y, size.z);
            const scale = maxDim > 1e-6 ? 10 / maxDim : 1;
            mesh.scale.set(scale, scale, scale);
            
            renderer.render(scene, camera);
        }, undefined, (error) => {
            console.error(`Error loading thumbnail for ${modelPath}:`, error);
        });
    }

    // التحميل المسبق للنماذج
    function preloadModels() {
        const loader = new THREE.STLLoader();
        allModels.forEach((model, index) => {
            if (index === 0) {
                loadingIndicator.classList.remove('hidden');
            }
            loader.load(model.path, (geometry) => {
                geometry.computeBoundingBox();
                geometry = simplifyGeometry(geometry, 0.5);
                const { jawType } = analyzeComponent(geometry, model.name);
                segmentJawGeometry(geometry, jawType);
                preloadedModels.set(index + 1, { geometry, jawType, name: model.name });
                console.log(`Preloaded model ${index + 1}: ${model.name}`);
                if (index === 0) {
                    loadingIndicator.classList.add('hidden');
                    loadMatchingModels(currentModelIndex);
                }
            }, undefined, (error) => {
                console.error(`Error preloading model ${index + 1}:`, error);
                if (index === 0) {
                    loadingIndicator.classList.add('hidden');
                }
            });
        });
    }

    // التحكم في العرض التلقائي
    function toggleAutoPlay() {
        if (isPlaying) {
            clearInterval(playInterval);
            isPlaying = false;
            document.getElementById('auto-play').querySelector('svg').innerHTML = `
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            `;
        } else {
            isPlaying = true;
            playInterval = setInterval(() => {
                if (currentModelIndex < allModels.length) {
                    previousModelIndex = currentModelIndex;
                    currentModelIndex++;
                } else {
                    previousModelIndex = currentModelIndex;
                    currentModelIndex = 1;
                }
                loadMatchingModels(currentModelIndex);
                applyDisplayMode();
                updateCounters();
            }, 3000);
            document.getElementById('auto-play').querySelector('svg').innerHTML = `
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            `;
        }
    }

    // إعداد المشهد الرئيسي
    function initMainScene() {
        scene = new THREE.Scene();
        scene.background = new THREE.Color(0xF5F5F5);
        
        camera = new THREE.PerspectiveCamera(75, mainContainer.clientWidth / mainContainer.clientHeight, 0.1, 1000);
        camera.position.set(0, 0, 20);
        
        renderer = new THREE.WebGLRenderer({ antialias: true });
        renderer.setSize(mainContainer.clientWidth, mainContainer.clientHeight);
        renderer.setPixelRatio(window.devicePixelRatio);
        mainContainer.appendChild(renderer.domElement);
        
        controls = new THREE.OrbitControls(camera, renderer.domElement);
        controls.enableDamping = true;
        controls.dampingFactor = 0.05;
        controls.minDistance = 5;
        controls.maxDistance = 50;
        controls.target.set(0, 0, 0);
        controls.update();
        
        const ambientLight = new THREE.AmbientLight(0xFFFFFF, 0.8);
        scene.add(ambientLight);
        const directionalLight = new THREE.DirectionalLight(0xFFFFFF, 0.6);
        directionalLight.position.set(5, 5, 5);
        scene.add(directionalLight);
        
        scene.add(modelsGroup);
        
        animate();
        
        window.addEventListener('resize', () => {
            camera.aspect = mainContainer.clientWidth / mainContainer.clientHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(mainContainer.clientWidth, mainContainer.clientHeight);
        });
    }

    // حلقة التحريك
    function animate() {
        requestAnimationFrame(animate);
        time += 0.02;
        controls.update();
        renderer.render(scene, camera);
    }

    // تحميل النماذج المطابقة
    function loadMatchingModels(index) {
        if (upperJawMesh) {
            modelsGroup.remove(upperJawMesh);
            upperJawMesh = null;
        }
        if (lowerJawMesh) {
            modelsGroup.remove(lowerJawMesh);
            lowerJawMesh = null;
        }

        const primaryModel = preloadedModels.get(index);
        if (!primaryModel) {
            console.warn(`Model at index ${index} not preloaded.`);
            return;
        }

        // إضافة الفهرس الحالي إلى النماذج المعروضة
        displayedModelIndices.add(index);

        const { geometry, jawType, name } = primaryModel;
        const materials = createJawMaterials(index);
        const mesh = new THREE.Mesh(geometry, [materials.gum, materials.teeth]);
        mesh.visible = displayMode === 'both' || (jawType === JawTypes.UPPER && displayMode === 'upper') || (jawType === JawTypes.LOWER && displayMode === 'lower');
        optimizeModelPosition(mesh, geometry, jawType);

        if (jawType === JawTypes.UPPER) {
            upperJawMesh = mesh;
        } else if (jawType === JawTypes.LOWER) {
            lowerJawMesh = mesh;
        }

        modelsGroup.add(mesh);

        // البحث عن فك مطابق
        let matchingIndex = -1;
        for (let i = 1; i <= allModels.length; i++) {
            if (i === index) continue;
            const otherModel = preloadedModels.get(i);
            if (!otherModel) continue;
            const isMatchingJaw = (jawType === JawTypes.UPPER && otherModel.jawType === JawTypes.LOWER) ||
                                 (jawType === JawTypes.LOWER && otherModel.jawType === JawTypes.UPPER);
            const isSameClient = allModels[i - 1].path.includes(allModels[index - 1].path.split('/').slice(0, -1).join('/'));
            if (isMatchingJaw && isSameClient) {
                matchingIndex = i;
                break;
            }
        }

        if (matchingIndex !== -1) {
            displayedModelIndices.add(matchingIndex);
            const matchingModel = preloadedModels.get(matchingIndex);
            const matchingMaterials = createJawMaterials(matchingIndex);
            const matchingMesh = new THREE.Mesh(matchingModel.geometry, [matchingMaterials.gum, matchingMaterials.teeth]);
            matchingMesh.visible = displayMode === 'both' || (matchingModel.jawType === JawTypes.UPPER && displayMode === 'upper') || (matchingModel.jawType === JawTypes.LOWER && displayMode === 'lower');
            optimizeModelPosition(matchingMesh, matchingModel.geometry, matchingModel.jawType);
            if (matchingModel.jawType === JawTypes.UPPER) {
                upperJawMesh = matchingMesh;
            } else {
                lowerJawMesh = matchingMesh;
            }
            modelsGroup.add(matchingMesh);

            // تطابق ألوان الفك العلوي مع السفلي
            if (jawType === JawTypes.LOWER && matchingModel.jawType === JawTypes.UPPER) {
                const lowerColors = modelColors.get(index) || (preloadedModels.get(index).geometry.attributes.color ? {
                    gum: new THREE.Color(preloadedModels.get(index).geometry.attributes.color.array[0], 
                                        preloadedModels.get(index).geometry.attributes.color.array[1], 
                                        preloadedModels.get(index).geometry.attributes.color.array[2]).getHex(),
                    teeth: new THREE.Color(preloadedModels.get(index).geometry.attributes.color.array[3], 
                                          preloadedModels.get(index).geometry.attributes.color.array[4], 
                                          preloadedModels.get(index).geometry.attributes.color.array[5]).getHex()
                } : { gum: 0xA52A2A, teeth: 0xFFF8E7 });
                updateModelColors(matchingIndex, lowerColors);
            } else if (jawType === JawTypes.UPPER && matchingModel.jawType === JawTypes.LOWER) {
                const upperColors = modelColors.get(index) || (preloadedModels.get(index).geometry.attributes.color ? {
                    gum: new THREE.Color(preloadedModels.get(index).geometry.attributes.color.array[0], 
                                        preloadedModels.get(index).geometry.attributes.color.array[1], 
                                        preloadedModels.get(index).geometry.attributes.color.array[2]).getHex(),
                    teeth: new THREE.Color(preloadedModels.get(index).geometry.attributes.color.array[3], 
                                          preloadedModels.get(index).geometry.attributes.color.array[4], 
                                          preloadedModels.get(index).geometry.attributes.color.array[5]).getHex()
                } : { gum: 0xA52A2A, teeth: 0xFFF8E7 });
                updateModelColors(matchingIndex, upperColors);
            }
        }

        // تطبيق ألوان الملف السابق على الملف الحالي إذا كان متلون
        if (previousModelIndex > 0) {
            const prevColors = modelColors.get(previousModelIndex);
            const defaultColors = { gum: 0xA52A2A, teeth: 0xFFF8E7 };
            const isPreviousColored = prevColors && (prevColors.gum !== defaultColors.gum || prevColors.teeth !== defaultColors.teeth);
            const originalColors = preloadedModels.get(index).geometry.attributes.color ? {
                gum: new THREE.Color(preloadedModels.get(index).geometry.attributes.color.array[0], 
                                    preloadedModels.get(index).geometry.attributes.color.array[1], 
                                    preloadedModels.get(index).geometry.attributes.color.array[2]).getHex(),
                teeth: new THREE.Color(preloadedModels.get(index).geometry.attributes.color.array[3], 
                                      preloadedModels.get(index).geometry.attributes.color.array[4], 
                                      preloadedModels.get(index).geometry.attributes.color.array[5]).getHex()
            } : null;
            
            if (isPreviousColored) {
                updateModelColors(index, prevColors);
                if (matchingIndex !== -1) {
                    updateModelColors(matchingIndex, prevColors);
                }
            } else if (originalColors) {
                updateModelColors(index, originalColors);
                if (matchingIndex !== -1) {
                    updateModelColors(matchingIndex, originalColors);
                }
            } else {
                updateModelColors(index, defaultColors);
                if (matchingIndex !== -1) {
                    updateModelColors(matchingIndex, defaultColors);
                }
            }
        }

        applyDisplayMode();
        toggleWireframe(isWireframe);
        updateModelInfo(name, geometry);
        updatePartsPanel();

        renderer.render(scene, camera);
    }

    // تحديث معلومات النموذج
    function updateModelInfo(modelName, geometry) {
        const details = document.getElementById('model-details');
        const vertexCount = geometry.attributes.position.count;
        const triangleCount = geometry.index ? geometry.index.count / 3 : vertexCount / 3;
        details.innerHTML = `
            <p><strong>اسم النموذج:</strong> ${modelName}</p>
            <p><strong>عدد الرؤوس:</strong> ${vertexCount}</p>
            <p><strong>عدد المثلثات:</strong> ${triangleCount}</p>
        `;
    }

    // تحديث لوحة الأجزاء لعرض جميع النماذج المعروضة
    function updatePartsPanel() {
        const partsList = document.getElementById('parts-list');
        partsList.innerHTML = '';

        const colorOptions = [
            { color: 0xFF0000, label: 'أحمر' },
            { color: 0x00FF00, label: 'أخضر' },
            { color: 0x0000FF, label: 'أزرق' },
            { color: 0xFFFF00, label: 'أصفر' },
            { color: 0xFFFFFF, label: 'أبيض' },
            { color: 0xA52A2A, label: 'افتراضي (لثة)' },
            { color: 0xFFF8E7, label: 'افتراضي (أسنان)' }
        ];

        // عرض النماذج من 1 إلى الفهرس الحالي
        const indicesToShow = Array.from(displayedModelIndices)
            .filter(i => i <= currentModelIndex)
            .sort((a, b) => a - b);

        indicesToShow.forEach(index => {
            const model = preloadedModels.get(index);
            if (!model) return;

            const parts = [];
            let isModelVisible = index === currentModelIndex;

            if (isModelVisible && (displayMode === 'both' || displayMode === 'upper') && model.jawType === JawTypes.UPPER) {
                parts.push(
                    { name: `الفك العلوي ${index} - اللثة`, jawType: JawTypes.UPPER, component: ComponentTypes.GUM, index },
                    { name: `الفك العلوي ${index} - الأسنان`, jawType: JawTypes.UPPER, component: ComponentTypes.TEETH, index }
                );
            } else if (isModelVisible && (displayMode === 'both' || displayMode === 'lower') && model.jawType === JawTypes.LOWER) {
                parts.push(
                    { name: `الفك السفلي ${index} - اللثة`, jawType: JawTypes.LOWER, component: ComponentTypes.GUM, index },
                    { name: `الفك السفلي ${index} - الأسنان`, jawType: JawTypes.LOWER, component: ComponentTypes.TEETH, index }
                );
            }

            // إضافة الفك المطابق إذا وجد
            let matchingIndex = -1;
            for (let i = 1; i <= allModels.length; i++) {
                if (i === index) continue;
                const otherModel = preloadedModels.get(i);
                if (!otherModel) continue;
                const isMatchingJaw = (model.jawType === JawTypes.UPPER && otherModel.jawType === JawTypes.LOWER) ||
                                     (model.jawType === JawTypes.LOWER && otherModel.jawType === JawTypes.UPPER);
                const isSameClient = allModels[i - 1].path.includes(allModels[index - 1].path.split('/').slice(0, -1).join('/'));
                if (isMatchingJaw && isSameClient) {
                    matchingIndex = i;
                    break;
                }
            }

            if (matchingIndex !== -1 && matchingIndex <= currentModelIndex) {
                const matchingModel = preloadedModels.get(matchingIndex);
                if (isModelVisible && (displayMode === 'both' || displayMode === 'upper') && matchingModel.jawType === JawTypes.UPPER) {
                    parts.push(
                        { name: `الفك العلوي ${matchingIndex} - اللثة`, jawType: JawTypes.UPPER, component: ComponentTypes.GUM, index: matchingIndex },
                        { name: `الفك العلوي ${matchingIndex} - الأسنان`, jawType: JawTypes.UPPER, component: ComponentTypes.TEETH, index: matchingIndex }
                    );
                } else if (isModelVisible && (displayMode === 'both' || displayMode === 'lower') && matchingModel.jawType === JawTypes.LOWER) {
                    parts.push(
                        { name: `الفك السفلي ${matchingIndex} - اللثة`, jawType: JawTypes.LOWER, component: ComponentTypes.GUM, index: matchingIndex },
                        { name: `الفك السفلي ${matchingIndex} - الأسنان`, jawType: JawTypes.LOWER, component: ComponentTypes.TEETH, index: matchingIndex }
                    );
                }
            }

            parts.forEach(part => {
                const partItem = document.createElement('div');
                partItem.className = 'part-item';
                partItem.innerHTML = `<span>${part.name}</span>`;
                const colorContainer = document.createElement('div');
                colorContainer.className = 'flex space-x-1 mt-1';
                colorOptions.forEach(opt => {
                    const colorSwatch = document.createElement('div');
                    colorSwatch.className = 'color-swatch';
                    colorSwatch.style.backgroundColor = `#${opt.color.toString(16).padStart(6, '0')}`;
                    colorSwatch.title = opt.label;
                    colorSwatch.addEventListener('click', () => {
                        const currentColors = modelColors.get(part.index) || (preloadedModels.get(part.index).geometry.attributes.color ? {
                            gum: new THREE.Color(preloadedModels.get(part.index).geometry.attributes.color.array[0], 
                                                preloadedModels.get(part.index).geometry.attributes.color.array[1], 
                                                preloadedModels.get(part.index).geometry.attributes.color.array[2]).getHex(),
                            teeth: new THREE.Color(preloadedModels.get(part.index).geometry.attributes.color.array[3], 
                                                  preloadedModels.get(part.index).geometry.attributes.color.array[4], 
                                                  preloadedModels.get(part.index).geometry.attributes.color.array[5]).getHex()
                        } : { gum: 0xA52A2A, teeth: 0xFFF8E7 });
                        const newColors = part.component === ComponentTypes.GUM
                            ? { ...currentColors, gum: opt.color }
                            : { ...currentColors, teeth: opt.color };
                        updateModelColors(part.index, newColors);
                        if (part.jawType === JawTypes.LOWER) {
                            const upperIndex = part.index === currentModelIndex ? matchingIndex : currentModelIndex;
                            if (upperIndex !== -1 && preloadedModels.get(upperIndex)?.jawType === JawTypes.UPPER) {
                                updateModelColors(upperIndex, newColors);
                            }
                        } else if (part.jawType === JawTypes.UPPER) {
                            const lowerIndex = part.index === currentModelIndex ? matchingIndex : currentModelIndex;
                            if (lowerIndex !== -1 && preloadedModels.get(lowerIndex)?.jawType === JawTypes.LOWER) {
                                updateModelColors(lowerIndex, newColors);
                            }
                        }
                    });
                    colorContainer.appendChild(colorSwatch);
                });
                partItem.appendChild(colorContainer);
                partsList.appendChild(partItem);
            });
        });
    }

    // تطبيق وضع العرض بناءً على الحالة
    function applyDisplayMode() {
        if (upperJawMesh) {
            upperJawMesh.visible = displayMode === 'both' || displayMode === 'upper';
            if (upperJawMesh.material) {
                upperJawMesh.material[0].visible = visibilityStates[JawTypes.UPPER][ComponentTypes.GUM];
                upperJawMesh.material[1].visible = visibilityStates[JawTypes.UPPER][ComponentTypes.TEETH];
            }
        }
        if (lowerJawMesh) {
            lowerJawMesh.visible = displayMode === 'both' || displayMode === 'lower';
            if (lowerJawMesh.material) {
                lowerJawMesh.material[0].visible = visibilityStates[JawTypes.LOWER][ComponentTypes.GUM];
                lowerJawMesh.material[1].visible = visibilityStates[JawTypes.LOWER][ComponentTypes.TEETH];
            }
        }
        updatePartsPanel();
    }

    // تبديل الإطار السلكي
    function toggleWireframe(enable) {
        isWireframe = enable;
        [upperJawMesh, lowerJawMesh].forEach(mesh => {
            if (mesh && mesh.material) {
                mesh.material.forEach(mat => {
                    mat.wireframe = enable;
                });
            }
        });
    }

    // إعادة ضبط العرض
    function resetView() {
        camera.position.set(0, 0, 20);
        controls.target.set(0, 0, 0);
        controls.update();
    }

    // تحديث العدادات
    function updateCounters() {
        document.querySelector('.model-counter').textContent = currentModelIndex;
    }

    // التقاط صورة للمشهد
    function takeScreenshot() {
        renderer.render(scene, camera);
        const dataURL = renderer.domElement.toDataURL('image/png');
        const link = document.createElement('a');
        link.href = dataURL;
        link.download = `model_screenshot_${currentModelIndex}.png`;
        link.click();
    }

    // تصدير النموذج
    function exportModel() {
        const exporter = new THREE.STLExporter();
        const stlString = exporter.parse(modelsGroup);
        const blob = new Blob([stlString], { type: 'text/plain' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = `model_${currentModelIndex}.stl`;
        link.click();
    }

    // إضافة ملاحظة
    function addAnnotation(type, text, position) {
        let geometry, material, mesh;
        if (type === 'text') {
            console.log('Text annotation added:', text, 'at position:', position);
            return;
        } else if (type === 'square') {
            geometry = new THREE.BoxGeometry(0.5, 0.5, 0.5);
            material = new THREE.MeshBasicMaterial({ color: 0x00FF00 });
        } else if (type === 'triangle') {
            geometry = new THREE.ConeGeometry(0.3, 0.6, 3);
            material = new THREE.MeshBasicMaterial({ color: 0xFFFF00 });
        }
        mesh = new THREE.Mesh(geometry, material);
        mesh.position.copy(position);
        scene.add(mesh);
        annotations.push({ mesh, type, text });
    }

    // إعداد أحداث الأزرار
    function setupEventListeners() {
        document.querySelector('.increase-model').addEventListener('click', () => {
            if (currentModelIndex < allModels.length) {
                previousModelIndex = currentModelIndex;
                currentModelIndex++;
                loadMatchingModels(currentModelIndex);
                applyDisplayMode();
                updateCounters();
            }
        });

        document.querySelector('.decrease-model').addEventListener('click', () => {
            if (currentModelIndex > 1) {
                previousModelIndex = currentModelIndex;
                currentModelIndex--;
                loadMatchingModels(currentModelIndex);
                applyDisplayMode();
                updateCounters();
            }
        });

        document.getElementById('upper-row').addEventListener('click', () => {
            displayMode = 'upper';
            applyDisplayMode();
        });

        document.getElementById('lower-row').addEventListener('click', () => {
            displayMode = 'lower';
            applyDisplayMode();
        });

        document.getElementById('both-rows').addEventListener('click', () => {
            displayMode = 'both';
            applyDisplayMode();
        });

        document.getElementById('auto-play').addEventListener('click', toggleAutoPlay);

        document.getElementById('zoom-in').addEventListener('click', () => {
            camera.position.z -= 1;
            controls.update();
        });

        document.getElementById('zoom-out').addEventListener('click', () => {
            camera.position.z += 1;
            controls.update();
        });

        document.querySelector('.screenshot-btn').addEventListener('click', takeScreenshot);

        document.getElementById('export-model').addEventListener('click', exportModel);

        document.getElementById('toggle-parts-panel').addEventListener('click', () => {
            const panel = document.getElementById('parts-panel');
            panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
        });

        document.getElementById('toggle-annotation-panel').addEventListener('click', () => {
            const panel = document.getElementById('annotation-panel');
            panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
        });

        document.getElementById('add-text-annotation').addEventListener('click', () => {
            const text = document.getElementById('annotation-text').value;
            if (text) {
                addAnnotation('text', text, new THREE.Vector3(0, 0, 0));
                document.getElementById('annotation-text').value = '';
            }
        });

        document.getElementById('add-square-annotation').addEventListener('click', () => {
            addAnnotation('square', '', new THREE.Vector3(0, 0, 0));
        });

        document.getElementById('add-triangle-annotation').addEventListener('click', () => {
            addAnnotation('triangle', '', new THREE.Vector3(0, 0, 0));
        });

        document.getElementById('wireframe-toggle').addEventListener('click', () => {
            toggleWireframe(!isWireframe);
        });

        document.getElementById('toggle-teeth').addEventListener('click', () => {
            visibilityStates[JawTypes.UPPER][ComponentTypes.TEETH] = !visibilityStates[JawTypes.UPPER][ComponentTypes.TEETH];
            visibilityStates[JawTypes.LOWER][ComponentTypes.TEETH] = !visibilityStates[JawTypes.LOWER][ComponentTypes.TEETH];
            applyDisplayMode();
        });

        document.getElementById('toggle-gum').addEventListener('click', () => {
            visibilityStates[JawTypes.UPPER][ComponentTypes.GUM] = !visibilityStates[JawTypes.UPPER][ComponentTypes.GUM];
            visibilityStates[JawTypes.LOWER][ComponentTypes.GUM] = !visibilityStates[JawTypes.LOWER][ComponentTypes.GUM];
            applyDisplayMode();
        });

        document.getElementById('toggle-upper-jaw').addEventListener('click', () => {
            displayMode = displayMode === 'upper' ? 'both' : 'upper';
            applyDisplayMode();
        });

        document.getElementById('toggle-lower-jaw').addEventListener('click', () => {
            displayMode = displayMode === 'lower' ? 'both' : 'lower';
            applyDisplayMode();
        });

        document.getElementById('reset-view').addEventListener('click', resetView);

        document.getElementById('show-all-parts').addEventListener('click', () => {
            visibilityStates[JawTypes.UPPER][ComponentTypes.TEETH] = true;
            visibilityStates[JawTypes.UPPER][ComponentTypes.GUM] = true;
            visibilityStates[JawTypes.LOWER][ComponentTypes.TEETH] = true;
            visibilityStates[JawTypes.LOWER][ComponentTypes.GUM] = true;
            displayMode = 'both';
            applyDisplayMode();
        });

        document.getElementById('color-first-model').addEventListener('click', () => {
            const colors = [0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00, 0xFFFFFF];
            const currentColors = modelColors.get(currentModelIndex) || (preloadedModels.get(currentModelIndex).geometry.attributes.color ? {
                gum: new THREE.Color(preloadedModels.get(currentModelIndex).geometry.attributes.color.array[0], 
                                    preloadedModels.get(currentModelIndex).geometry.attributes.color.array[1], 
                                    preloadedModels.get(currentModelIndex).geometry.attributes.color.array[2]).getHex(),
                teeth: new THREE.Color(preloadedModels.get(currentModelIndex).geometry.attributes.color.array[3], 
                                      preloadedModels.get(currentModelIndex).geometry.attributes.color.array[4], 
                                      preloadedModels.get(currentModelIndex).geometry.attributes.color.array[5]).getHex()
            } : { gum: 0xA52A2A, teeth: 0xFFF8E7 });
            const nextColor = colors[(colors.indexOf(currentColors.gum) + 1) % colors.length] || colors[0];
            const newColors = { gum: nextColor, teeth: currentColors.teeth };
            updateModelColors(currentModelIndex, newColors);
            const matchingIndex = [...preloadedModels.keys()].find(i => {
                if (i === currentModelIndex) return false;
                const otherModel = preloadedModels.get(i);
                const primaryModel = preloadedModels.get(currentModelIndex);
                const isMatchingJaw = (primaryModel.jawType === JawTypes.UPPER && otherModel.jawType === JawTypes.LOWER) ||
                                     (primaryModel.jawType === JawTypes.LOWER && otherModel.jawType === JawTypes.UPPER);
                const isSameClient = allModels[i - 1].path.includes(allModels[currentModelIndex - 1].path.split('/').slice(0, -1).join('/'));
                return isMatchingJaw && isSameClient;
            });
            if (matchingIndex !== undefined) {
                updateModelColors(matchingIndex, newColors);
            }
        });

        document.querySelectorAll('.color-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const color = parseInt(btn.dataset.color, 16);
                const currentColors = modelColors.get(currentModelIndex) || (preloadedModels.get(currentModelIndex).geometry.attributes.color ? {
                    gum: new THREE.Color(preloadedModels.get(currentModelIndex).geometry.attributes.color.array[0], 
                                        preloadedModels.get(currentModelIndex).geometry.attributes.color.array[1], 
                                        preloadedModels.get(currentModelIndex).geometry.attributes.color.array[2]).getHex(),
                    teeth: new THREE.Color(preloadedModels.get(currentModelIndex).geometry.attributes.color.array[3], 
                                          preloadedModels.get(currentModelIndex).geometry.attributes.color.array[4], 
                                          preloadedModels.get(currentModelIndex).geometry.attributes.color.array[5]).getHex()
                } : { gum: 0xA52A2A, teeth: 0xFFF8E7 });
                const newColors = { gum: color, teeth: currentColors.teeth };
                updateModelColors(currentModelIndex, newColors);
                const matchingIndex = [...preloadedModels.keys()].find(i => {
                    if (i === currentModelIndex) return false;
                    const otherModel = preloadedModels.get(i);
                    const primaryModel = preloadedModels.get(currentModelIndex);
                    const isMatchingJaw = (primaryModel.jawType === JawTypes.UPPER && otherModel.jawType === JawTypes.LOWER) ||
                                         (primaryModel.jawType === JawTypes.LOWER && otherModel.jawType === JawTypes.UPPER);
                    const isSameClient = allModels[i - 1].path.includes(allModels[currentModelIndex - 1].path.split('/').slice(0, -1).join('/'));
                    return isMatchingJaw && isSameClient;
                });
                if (matchingIndex !== undefined) {
                    updateModelColors(matchingIndex, newColors);
                }
            });
        });

        document.getElementById('info-button').addEventListener('click', () => {
            const info = document.getElementById('model-info');
            info.classList.toggle('hidden');
        });

        document.getElementById('comment-form').addEventListener('submit', (e) => {
            e.preventDefault();
            const commentText = document.getElementById('comment-text').value;
            if (commentText.trim()) {
                const commentItem = document.createElement('div');
                commentItem.className = 'comment-item';
                commentItem.innerHTML = `
                    <p>${commentText.replace(/\n/g, '<br>')}</p>
                    <small>تم الإضافة في: ${new Date().toLocaleString('ar-EG')}</small>
                `;
                document.getElementById('comments-list').appendChild(commentItem);
                document.getElementById('comments-list').querySelector('.text-gray-500').style.display = 'none';
                document.getElementById('comment-text').value = '';
            }
        });

        document.querySelectorAll('.model-item').forEach(item => {
            item.addEventListener('click', () => {
                previousModelIndex = currentModelIndex;
                currentModelIndex = parseInt(item.dataset.index) + 1;
                loadMatchingModels(currentModelIndex);
                updateCounters();
            });
        });
    }

    // إنشاء الصور المصغرة
    function setupThumbnails() {
        document.querySelectorAll('.model-item').forEach(item => {
            const thumbnail = item.querySelector('.model-thumbnail');
            const modelPath = item.dataset.path;
            createThumbnail(thumbnail, modelPath);
        });
    }

    // تهيئة التطبيق
    initMainScene();
    setupEventListeners();
    setupThumbnails();
    preloadModels();
    updateCounters();
});
    </script>
</body>
</html>
فالكود ده عاوز اعمل حاجة احترافية اوي 
وهي ان اضيف زر واسمه يكون حفظ الوضع الحالي وفكرته انه هيحفظ النماذج المعروضه فالامام ويتم انشااء لينك للعرض 
ولمه يتم الضغط على اللينك يتم عرضه في صفحة بنفس الوضع كما ضغط حفظ واقدر اخد الللينك ده ابعته لاي حد عشان يشوف الملف
اعمل المطلوب وارسل الكود كامل ورد بالعربي
وباكدلك انك لا تغير اي شئ فالشكل ولا تغير اي شئ فالوظايف 
فقط فقط ضيف المطلوب ولا تغير او تلعب في اي امور غير اللي طلبتها 
وارسل كود الصفحة اللي هيتم عرض فيهاا النموذج اللي طالع من اللينك من العلم انا عاوزها تكون شبه الصفحة الاساسية بس مفهاش اي تعديلات او الاضافات الموجوده 
عرض النموذج فقط