// Sample/demo content text used in demo mode as substitutes for server data.
//
// These strings represent actual data records (company names, role names,
// descriptions, ticket titles, message bodies, etc.) that in non-demo mode
// would be replaced by real server data.
//
// All strings are provided in both English and Persian. The active language
// is read from [UiText.isPersian] so a single call to
// [UiText.configureLanguage] is sufficient to switch both UI copy and demo
// content simultaneously.

// ignore_for_file: unused_element

import 'ui_text.dart';

class MockDataText {
  const MockDataText._();

  static String _t(String en, String fa) => UiText.isPersian ? fa : en;

  // ── Demo account credentials ─────────────────────────────────────────────
  static const String demoEmail = 'demo@autocreat.io';
  static const String adminDemoEmail = 'admin@demo.com';
  static const String adminDemoPassword = 'password123';

  // ── Company ──────────────────────────────────────────────────────────────
  static String get companyName => _t(
        'Horizon Digital Agency',
        'آژانس دیجیتال هورایزن',
      );
  static String get companyDescription => _t(
        'Full-service digital transformation agency helping businesses modernise their operations and customer journeys.',
        'آژانس تحول دیجیتال با خدمات کامل که به کسب‌وکارها در نوسازی عملیات و سفرهای مشتری کمک می‌کند.',
      );
  static String get companyIndustry => _t('Technology', 'فناوری');

  // ── Role names & descriptions ─────────────────────────────────────────────
  static String get roleAdministratorName => _t('Administrator', 'مدیر سیستم');
  static String get roleAdministratorDesc => _t(
        'Full access to all resources and settings within the organisation.',
        'دسترسی کامل به تمام منابع و تنظیمات سازمان.',
      );
  static String get roleOperationsManagerName =>
      _t('Operations Manager', 'مدیر عملیات');
  static String get roleOperationsManagerDesc => _t(
        'Manages flows, forms, tickets, and instances. Read-only access to users and roles.',
        'مدیریت گردش‌کارها، فرم‌ها، تیکت‌ها و نمونه‌ها. دسترسی فقط‌خواندنی به کاربران و نقش‌ها.',
      );
  static String get roleSupportAgentName =>
      _t('Support Agent', 'کارشناس پشتیبانی');
  static String get roleSupportAgentDesc => _t(
        'Create, update and resolve support tickets. View users and flows.',
        'ایجاد، به‌روزرسانی و رفع تیکت‌های پشتیبانی. مشاهده کاربران و گردش‌کارها.',
      );
  static String get roleDeveloperName => _t('Developer', 'توسعه‌دهنده');
  static String get roleDeveloperDesc => _t(
        'Full CRUD on flows, forms, models, and letter templates. Read-only on everything else.',
        'عملیات کامل روی گردش‌کارها، فرم‌ها، مدل‌ها و قالب‌های نامه. دسترسی فقط‌خواندنی به سایر منابع.',
      );
  static String get roleViewerName => _t('Viewer', 'بیننده');
  static String get roleViewerDesc => _t(
        'Read-only access to all non-sensitive resources.',
        'دسترسی فقط‌خواندنی به تمام منابع غیرحساس.',
      );

  // ── Flow names & descriptions ─────────────────────────────────────────────
  static String get flow1Name => _t('Client Onboarding', 'پذیرش مشتری');
  static String get flow1Desc => _t(
        'End-to-end onboarding pipeline: intake form → contract signing → kickoff scheduling → welcome letter.',
        'فرآیند کامل پذیرش: فرم اولیه ← امضای قرارداد ← زمان‌بندی جلسه آغازین ← نامه خوشامدگویی.',
      );
  static String get flow2Name => _t('Bug Report Triage', 'بررسی گزارش اشکال');
  static String get flow2Desc => _t(
        'Automated triage pipeline for incoming bug reports: classify → assign → resolve → close.',
        'فرآیند خودکار بررسی گزارش‌های اشکال: دسته‌بندی ← تخصیص ← رفع ← بستن.',
      );
  static String get flow3Name =>
      _t('Employee Leave Request', 'درخواست مرخصی کارمند');
  static String get flow3Desc => _t(
        'HR leave-request flow with manager approval and automated notification letters.',
        'فرآیند درخواست مرخصی با تأیید مدیر و ارسال خودکار نامه اطلاع‌رسانی.',
      );

  // Flow node labels
  static String get nodeStart => _t('Start', 'شروع');
  static String get nodeEnd => _t('End', 'پایان');
  static String get nodeIntakeForm => _t('Intake Form', 'فرم اولیه');
  static String get nodeApprovalQuestion => _t('Approval?', 'تأیید؟');
  static String get nodeSendWelcomeLetter =>
      _t('Send Welcome Letter', 'ارسال نامه خوشامدگویی');
  static String get nodeBugReportForm =>
      _t('Bug Report Form', 'فرم گزارش اشکال');
  static String get nodeSeverityCheck =>
      _t('Severity Check', 'بررسی شدت خطا');
  static String get nodeEscalateToDevLead =>
      _t('Escalate to Dev Lead', 'ارجاع به سرپرست توسعه');
  static String get nodeAssignToDeveloper =>
      _t('Assign to Developer', 'تخصیص به توسعه‌دهنده');
  static String get nodeLeaveRequestForm =>
      _t('Leave Request Form', 'فرم درخواست مرخصی');
  static String get nodeManagerApproval =>
      _t('Manager Approval', 'تأیید مدیر');
  static String get nodeSendApprovalLetter =>
      _t('Send Approval Letter', 'ارسال نامه تأیید');
  static String get nodeSendDenialLetter =>
      _t('Send Denial Letter', 'ارسال نامه رد');

  // Flow branch & edge labels
  static String get branchApproved => _t('Approved', 'تأیید شد');
  static String get branchRejected => _t('Rejected', 'رد شد');
  static String get branchDenied => _t('Denied', 'رد شد');
  static String get branchCritical => _t('Critical', 'بحرانی');
  static String get branchNormal => _t('Normal', 'عادی');

  // ── Form names & descriptions ─────────────────────────────────────────────
  static String get form1Name => _t('Client Intake Form', 'فرم اولیه مشتری');
  static String get form1Desc => _t(
        'Collects new client contact details, project scope, and budget range during the onboarding flow.',
        'اطلاعات تماس مشتری جدید، محدوده پروژه و بودجه را در فرآیند پذیرش جمع‌آوری می‌کند.',
      );
  static String get form2Name => _t('Bug Report Form', 'فرم گزارش اشکال');
  static String get form2Desc => _t(
        'Structured form for reporting software defects with severity, steps to reproduce, and attachments.',
        'فرم ساختاریافته برای گزارش نقص نرم‌افزاری با شدت خطا، مراحل بازتولید و پیوست.',
      );
  static String get form3Name =>
      _t('Employee Leave Request', 'درخواست مرخصی کارمند');
  static String get form3Desc => _t(
        'Annual, sick, and personal leave request form with date range and reason.',
        'فرم درخواست مرخصی سالانه، استعلاجی و شخصی با بازه تاریخ و دلیل.',
      );
  static String get form4Name =>
      _t('Project Feedback Survey', 'نظرسنجی بازخورد پروژه');
  static String get form4Desc => _t(
        'Post-delivery client satisfaction survey with NPS score, rating, and open comments.',
        'نظرسنجی رضایت مشتری پس از تحویل با امتیاز NPS، رتبه‌بندی و نظرات آزاد.',
      );

  // Form field labels
  static String get fieldCompanyName => _t('Company Name', 'نام شرکت');
  static String get fieldPrimaryContact =>
      _t('Primary Contact', 'مخاطب اصلی');
  static String get fieldEmailAddress => _t('Email Address', 'آدرس ایمیل');
  static String get fieldProjectType => _t('Project Type', 'نوع پروژه');
  static String get fieldEstimatedBudget =>
      _t('Estimated Budget (USD)', 'بودجه تخمینی (دلار)');
  static String get fieldProjectDescription =>
      _t('Project Description', 'توضیحات پروژه');
  static String get fieldDesiredStartDate =>
      _t('Desired Start Date', 'تاریخ شروع مطلوب');
  static String get fieldBugTitle => _t('Bug Title', 'عنوان اشکال');
  static String get fieldSeverity => _t('Severity', 'شدت خطا');
  static String get fieldStepsToReproduce =>
      _t('Steps to Reproduce', 'مراحل بازتولید');
  static String get fieldExpectedBehaviour =>
      _t('Expected Behaviour', 'رفتار مورد انتظار');
  static String get fieldActualBehaviour =>
      _t('Actual Behaviour', 'رفتار واقعی');
  static String get fieldScreenshotsLogs =>
      _t('Screenshots / Logs', 'اسکرین‌شات / گزارش‌ها');
  static String get fieldLeaveType => _t('Leave Type', 'نوع مرخصی');
  static String get fieldStartDate => _t('Start Date', 'تاریخ شروع');
  static String get fieldEndDate => _t('End Date', 'تاریخ پایان');
  static String get fieldReason => _t('Reason', 'دلیل');
  static String get fieldCoverArranged =>
      _t('Cover Arranged', 'جایگزین تعیین شده');
  static String get fieldOverallSatisfaction =>
      _t('Overall Satisfaction', 'رضایت کلی');
  static String get fieldNPS =>
      _t('Net Promoter Score (0–10)', 'امتیاز ترویج‌دهنده خالص (۰–۱۰)');
  static String get fieldWhatWentWell =>
      _t('What went well?', 'چه چیزی خوب پیش رفت؟');
  static String get fieldAdditionalComments =>
      _t('Additional Comments', 'نظرات اضافی');

  // Form placeholders
  static String get phAcmeCorp => _t('Acme Corp', 'شرکت نمونه');
  static String get phFullName => _t('Full name', 'نام کامل');
  static String get phContactEmail =>
      _t('contact@example.com', 'contact@example.com');
  static String get phBudget => _t('50000', '50000');
  static String get phProjectDescGoals => _t(
        'Describe the goals and requirements...',
        'اهداف و نیازمندی‌ها را توضیح دهید...',
      );
  static String get phBugSummary =>
      _t('Short summary of the issue', 'خلاصه کوتاه مشکل');
  static String get phStepsToReproduce => _t(
        '1. Navigate to...\n2. Click...',
        '۱. به ... بروید\n۲. کلیک کنید...',
      );
  static String get phOptionalDetails =>
      _t('Optional additional details', 'جزئیات اضافی اختیاری');
  static String get phAnyFeedback =>
      _t('Any other feedback...', 'هر بازخورد دیگری...');

  // Form option labels
  static String get optWebApp => _t('Web Application', 'برنامه وب');
  static String get optMobileApp => _t('Mobile Application', 'برنامه موبایل');
  static String get optDataPlatform => _t('Data Platform', 'پلتفرم داده');
  static String get optIntegration =>
      _t('Systems Integration', 'یکپارچه‌سازی سیستم‌ها');
  static String get optCriticalSeverity =>
      _t('Critical — system down', 'بحرانی — سیستم از دسترس خارج');
  static String get optHighSeverity =>
      _t('High — major feature broken', 'زیاد — ویژگی اصلی خراب است');
  static String get optMediumSeverity =>
      _t('Medium — degraded experience', 'متوسط — تجربه کاربری ضعیف');
  static String get optLowSeverity =>
      _t('Low — cosmetic / minor', 'کم — ظاهری / جزئی');
  static String get optAnnualLeave => _t('Annual Leave', 'مرخصی سالانه');
  static String get optSickLeave => _t('Sick Leave', 'مرخصی استعلاجی');
  static String get optPersonalLeave => _t('Personal Leave', 'مرخصی شخصی');
  static String get optParentalLeave => _t('Parental Leave', 'مرخصی والدین');
  static String get optCommunication => _t('Communication', 'ارتباطات');
  static String get optDeliveryQuality =>
      _t('Delivery Quality', 'کیفیت تحویل');
  static String get optOnTimeDelivery =>
      _t('On-Time Delivery', 'تحویل به موقع');
  static String get optPostLaunchSupport =>
      _t('Post-Launch Support', 'پشتیبانی پس از راه‌اندازی');
  static String get optValueForMoney => _t('Value for Money', 'ارزش در برابر هزینه');

  // ── Letter template names, descriptions & content ─────────────────────────
  static String get letter1Name => _t('Welcome Letter', 'نامه خوشامدگویی');
  static String get letter1Desc => _t(
        'Sent to new clients after onboarding approval. Introduces the team and next steps.',
        'پس از تأیید پذیرش برای مشتریان جدید ارسال می‌شود. تیم و مراحل بعدی را معرفی می‌کند.',
      );
  static String get letter1Content => _t(
        'Dear {{client_name}},\n\n'
        'Welcome to Horizon Digital Agency! We are thrilled to have {{company_name}} as a new client.\n\n'
        'Your dedicated project manager is {{pm_name}}, who will be in touch within 24 hours to schedule your kickoff call.\n\n'
        'In the meantime, please find attached your signed contract and the project brief for your records.\n\n'
        'We look forward to delivering outstanding results together.\n\n'
        'Warm regards,\n{{sender_name}}\nHorizon Digital Agency',
        'مشتری گرامی {{client_name}}،\n\n'
        'به آژانس دیجیتال هورایزن خوش آمدید! ما مفتخریم که {{company_name}} را به عنوان مشتری جدید داریم.\n\n'
        'مدیر پروژه اختصاصی شما {{pm_name}} است که ظرف ۲۴ ساعت برای برنامه‌ریزی جلسه آغازین با شما تماس خواهد گرفت.\n\n'
        'در این بین، لطفاً قرارداد امضاشده و خلاصه پروژه پیوست شده را برای سوابق خود دریافت کنید.\n\n'
        'مشتاق ارائه نتایج درخشان در کنار شما هستیم.\n\n'
        'با احترام،\n{{sender_name}}\nآژانس دیجیتال هورایزن',
      );
  static String get letter1Category => _t('Onboarding', 'پذیرش');

  static String get letter2Name =>
      _t('Leave Approval Notice', 'اطلاعیه تأیید مرخصی');
  static String get letter2Desc => _t(
        'HR notification confirming an approved employee leave request.',
        'اطلاعیه منابع انسانی مبنی بر تأیید درخواست مرخصی کارمند.',
      );
  static String get letter2Content => _t(
        'Dear {{employee_name}},\n\n'
        'This letter confirms that your leave request has been approved.\n\n'
        'Leave Type: {{leave_type}}\nStart Date: {{start_date}}\nEnd Date: {{end_date}}\n\n'
        'Please ensure all pending tasks are handed over before your leave begins.\n\n'
        'Should you have any questions, please contact HR at hr@horizondigital.io.\n\n'
        'Best regards,\n{{manager_name}}\nHorizon Digital Agency — HR',
        'همکار گرامی {{employee_name}}،\n\n'
        'این نامه تأیید می‌کند که درخواست مرخصی شما تأیید شده است.\n\n'
        'نوع مرخصی: {{leave_type}}\nتاریخ شروع: {{start_date}}\nتاریخ پایان: {{end_date}}\n\n'
        'لطفاً اطمینان حاصل کنید که تمام وظایف معلق قبل از شروع مرخصی به فرد جایگزین تحویل داده شده‌اند.\n\n'
        'در صورت داشتن سؤال، با واحد منابع انسانی از طریق hr@horizondigital.io تماس بگیرید.\n\n'
        'با احترام،\n{{manager_name}}\nآژانس دیجیتال هورایزن — منابع انسانی',
      );
  static String get letter2Category => _t('HR', 'منابع انسانی');

  static String get letter3Name =>
      _t('Project Completion Certificate', 'گواهی تکمیل پروژه');
  static String get letter3Desc => _t(
        'Formal certificate issued to clients on successful project delivery.',
        'گواهی رسمی صادر شده برای مشتریان پس از تحویل موفق پروژه.',
      );
  static String get letter3Content => _t(
        'CERTIFICATE OF PROJECT COMPLETION\n\n'
        'This is to certify that the project "{{project_name}}" commissioned by {{client_company}} '
        'has been successfully completed by Horizon Digital Agency on {{completion_date}}.\n\n'
        'Project Scope: {{project_scope}}\nDelivery Standard: {{standard}}\n\n'
        'All deliverables have been tested, accepted, and handed over as per the agreed specifications.\n\n'
        'Authorised by: {{authoriser_name}}\nDate: {{issue_date}}\n\n'
        'Horizon Digital Agency\nhttps://horizondigital.io',
        'گواهی تکمیل پروژه\n\n'
        'بدینوسیله تأیید می‌شود که پروژه "{{project_name}}" سفارش داده شده توسط {{client_company}} '
        'در تاریخ {{completion_date}} با موفقیت توسط آژانس دیجیتال هورایزن به انجام رسیده است.\n\n'
        'محدوده پروژه: {{project_scope}}\nاستاندارد تحویل: {{standard}}\n\n'
        'تمام تحویلی‌ها آزمایش، تأیید و طبق مشخصات توافق شده تحویل داده شده‌اند.\n\n'
        'مجاز توسط: {{authoriser_name}}\nتاریخ: {{issue_date}}\n\n'
        'آژانس دیجیتال هورایزن\nhttps://horizondigital.io',
      );
  static String get letter3Category => _t('Delivery', 'تحویل');

  // ── Model definitions ─────────────────────────────────────────────────────
  static String get model1Name => _t('Client', 'مشتری');
  static String get model1Desc => _t(
        'Core entity representing an external client organisation.',
        'موجودیت اصلی نمایانگر یک سازمان مشتری خارجی.',
      );
  static String get model2Name => _t('Project', 'پروژه');
  static String get model2Desc => _t(
        'Tracks individual delivery projects linked to a client.',
        'پیگیری پروژه‌های تحویل فردی مرتبط با یک مشتری.',
      );

  // ── Ticket titles & descriptions ──────────────────────────────────────────
  static String get ticket1Title => _t(
        'Login page crashes on iOS 17.4 Safari',
        'صفحه ورود در Safari نسخه iOS 17.4 خراب می‌شود',
      );
  static String get ticket1Desc => _t(
        'Users on iPhone 15 running iOS 17.4 and using Safari cannot complete login — the page crashes after submitting credentials.',
        'کاربران آیفون ۱۵ با iOS 17.4 که از Safari استفاده می‌کنند قادر به تکمیل ورود نیستند — صفحه پس از ارسال اطلاعات خراب می‌شود.',
      );
  static String get ticket2Title => _t(
        'Flow editor canvas zoom reset on node drag',
        'بزرگ‌نمایی بوم ویرایشگر گردش‌کار هنگام کشیدن گره بازنشانی می‌شود',
      );
  static String get ticket2Desc => _t(
        'When dragging a node in the flow editor, the canvas zoom level resets to 100% unexpectedly.',
        'هنگام کشیدن یک گره در ویرایشگر گردش‌کار، سطح بزرگ‌نمایی بوم به‌طور غیرمنتظره به ۱۰۰٪ بازنشانی می‌شود.',
      );
  static String get ticket3Title => _t(
        'Add CSV export for user list',
        'افزودن قابلیت خروجی CSV برای لیست کاربران',
      );
  static String get ticket3Desc => _t(
        'Clients have requested the ability to export the full user list as a CSV for their own records.',
        'مشتریان درخواست کرده‌اند که بتوانند لیست کامل کاربران را به صورت CSV برای سوابق خود خروجی بگیرند.',
      );
  static String get ticket4Title => _t(
        'Email notifications not sending for ticket assignment',
        'اطلاعیه‌های ایمیل برای تخصیص تیکت ارسال نمی‌شوند',
      );
  static String get ticket4Desc => _t(
        'When a ticket is assigned to a user, the email notification is not being sent. Confirmed across all SMTP configurations.',
        'هنگامی که یک تیکت به کاربری تخصیص داده می‌شود، اطلاعیه ایمیل ارسال نمی‌شود. در تمام پیکربندی‌های SMTP تأیید شده است.',
      );
  static String get ticket5Title => _t(
        'Role permissions not applying to form builder',
        'مجوزهای نقش در سازنده فرم اعمال نمی‌شوند',
      );
  static String get ticket5Desc => _t(
        'Users with the Viewer role can still edit form fields in the form builder despite canUpdate being false on the forms resource.',
        'کاربران با نقش بیننده هنوز هم می‌توانند فیلدهای فرم را در سازنده فرم ویرایش کنند، با اینکه canUpdate برای منبع فرم‌ها false است.',
      );
  static String get ticket6Title => _t(
        'Letter template variables not substituting on preview',
        'متغیرهای قالب نامه در پیش‌نمایش جایگزین نمی‌شوند',
      );
  static String get ticket6Desc => _t(
        'Clicking "Preview" in the letter template editor shows the raw {{variable}} tags instead of substituted sample values.',
        'کلیک روی "پیش‌نمایش" در ویرایشگر قالب نامه تگ‌های {{متغیر}} خام را به جای مقادیر نمونه جایگزین شده نشان می‌دهد.',
      );
  static String get ticket7Title => _t(
        'Dark mode: sidebar icon colours inconsistent',
        'حالت تاریک: رنگ‌های آیکون نوار کناری ناهماهنگ هستند',
      );
  static String get ticket7Desc => _t(
        'In dark mode, several sidebar navigation icons appear with a light background box rather than the expected transparent fill.',
        'در حالت تاریک، چند آیکون ناوبری نوار کناری با کادر پس‌زمینه روشن به جای پر شدن شفاف مورد انتظار نمایش داده می‌شوند.',
      );
  static String get ticket8Title => _t(
        'Onboarding flow — approval step silently fails for large files',
        'گردش‌کار پذیرش — مرحله تأیید برای فایل‌های بزرگ بدون خطا شکست می‌خورد',
      );
  static String get ticket8Desc => _t(
        'When a client uploads a file larger than 10 MB in the Intake Form step, the approval step fails with no error displayed.',
        'هنگامی که مشتری فایلی بزرگ‌تر از ۱۰ مگابایت در مرحله فرم اولیه آپلود می‌کند، مرحله تأیید بدون نمایش خطا شکست می‌خورد.',
      );

  // ── Ticket messages ───────────────────────────────────────────────────────
  // Ticket 1
  static String get msg0101 => _t(
        'Reproduced on iPhone 15 Pro and SE 3rd gen. Both crash on form submit.',
        'روی آیفون ۱۵ پرو و SE نسل سوم بازتولید شد. هر دو دستگاه هنگام ارسال فرم خراب می‌شوند.',
      );
  static String get msg0102 => _t(
        'Checking the Safari console logs — looks like a memory issue with the auth token storage. Will patch today.',
        'در حال بررسی گزارش‌های کنسول Safari — به نظر مشکل حافظه در ذخیره‌سازی توکن احراز هویت است. امروز پچ می‌زنم.',
      );
  static String get msg0103 => _t(
        'This is blocking onboarding for the Apex client. Priority escalated to Urgent.',
        'این مانع پذیرش مشتری Apex شده است. اولویت به فوری ارتقا یافت.',
      );
  static String get msg0104 => _t(
        'Fix deployed to staging. Needs QA sign-off before going to production.',
        'اصلاح در محیط استیجینگ مستقر شد. قبل از انتقال به محیط تولید نیاز به تأیید QA دارد.',
      );
  // Ticket 2
  static String get msg0201 => _t(
        'Happens consistently on all browsers. Steps: open editor → zoom to 150% → drag any node → zoom resets.',
        'در تمام مرورگرها به‌طور مداوم رخ می‌دهد. مراحل: باز کردن ویرایشگر ← بزرگ‌نمایی به ۱۵۰٪ ← کشیدن هر گره ← بزرگ‌نمایی بازنشانی می‌شود.',
      );
  static String get msg0202 => _t(
        'Confirmed. Blocking the UX review this week. Assign highest priority.',
        'تأیید شد. این هفته جلسه بررسی UX را مسدود کرده است. بالاترین اولویت را تخصیص دهید.',
      );
  static String get msg0203 => _t(
        'Root cause identified: scale state is not persisted in the zoom handler. Working on fix.',
        'علت اصلی شناسایی شد: وضعیت مقیاس در کنترل‌کننده بزرگ‌نمایی ذخیره نمی‌شود. در حال کار روی اصلاح.',
      );
  // Ticket 3
  static String get msg0301 => _t(
        'At least 3 enterprise clients have requested this. Should include: name, email, role, last login, status.',
        'حداقل ۳ مشتری سازمانی این را درخواست کرده‌اند. باید شامل باشد: نام، ایمیل، نقش، آخرین ورود، وضعیت.',
      );
  static String get msg0302 => _t(
        'Will add to the next sprint. ETA end of week.',
        'در اسپرینت بعدی اضافه می‌شود. زمان تخمینی: پایان هفته.',
      );
  // Ticket 4
  static String get msg0401 => _t(
        'Multiple users confirming no emails on ticket assignment. Checked spam — not there either.',
        'کاربران متعددی تأیید کردند که هنگام تخصیص تیکت ایمیلی دریافت نمی‌شود. اسپم بررسی شد — آنجا هم نیست.',
      );
  static String get msg0402 => _t(
        'Investigating the notification service. Will check queue logs.',
        'در حال بررسی سرویس اطلاعیه. گزارش‌های صف را بررسی می‌کنم.',
      );
  static String get msg0403 => _t(
        'Found it — a misconfiguration in the event handler was silently swallowing the SMTP error. Deploying fix now.',
        'پیدا کردم — یک پیکربندی اشتباه در کنترل‌کننده رویداد خطای SMTP را بدون نمایش می‌بلعید. اکنون اصلاح را مستقر می‌کنم.',
      );
  static String get msg0404 => _t(
        'Just received a test notification. Fix confirmed working.',
        'همین الان یک اطلاعیه آزمایشی دریافت کردم. اصلاح تأیید شد.',
      );
  static String get msg0405 => _t(
        'Closing this ticket. Great turnaround time.',
        'این تیکت را می‌بندم. زمان پاسخگویی عالی بود.',
      );
  // Ticket 5
  static String get msg0501 => _t(
        'Tested with a Viewer account — I can drag fields and change labels. This is a security risk.',
        'با یک حساب بیننده آزمایش کردم — می‌توانم فیلدها را بکشم و برچسب‌ها را تغییر دهم. این یک خطر امنیتی است.',
      );
  static String get msg0502 => _t(
        'Security issue confirmed. Escalating to High. James, please fix before the next client demo.',
        'مشکل امنیتی تأیید شد. به بالا ارتقا می‌دهم. جیمز، لطفاً قبل از دموی مشتری بعدی رفع کن.',
      );
  static String get msg0503 => _t(
        'The form builder widget was not checking the permission guard on render. Fix in progress — ETA tomorrow.',
        'ویجت سازنده فرم در هنگام رندر محافظ مجوز را بررسی نمی‌کرد. اصلاح در حال انجام است — زمان تخمینی: فردا.',
      );
  // Ticket 6
  static String get msg0601 => _t(
        'The {{client_name}} and {{sender_name}} tags are showing raw in the preview pane.',
        'تگ‌های {{client_name}} و {{sender_name}} در پنل پیش‌نمایش خام نمایش داده می‌شوند.',
      );
  static String get msg0602 => _t(
        'Good catch. The preview renderer was using the raw content field instead of the processed one. Fixed in v1.2.3.',
        'تشخیص خوبی بود. رندرکننده پیش‌نمایش به جای محتوای پردازش شده از فیلد محتوای خام استفاده می‌کرد. در v1.2.3 رفع شد.',
      );
  static String get msg0603 => _t('Confirmed fixed. Closing.', 'رفع تأیید شد. بستن.');
  // Ticket 7
  static String get msg0701 => _t(
        'Affects the Tickets, Roles, and Letters icons. Screenshot attached (not available in demo).',
        'آیکون‌های تیکت‌ها، نقش‌ها و نامه‌ها را تحت تأثیر قرار می‌دهد. اسکرین‌شات پیوست شد (در حالت دمو موجود نیست).',
      );
  static String get msg0702 => _t(
        'Those icons have a hardcoded white background in their SVG. Will update them.',
        'این آیکون‌ها پس‌زمینه سفید کدگذاری شده در SVG دارند. آن‌ها را به‌روز می‌کنم.',
      );
  static String get msg0703 => _t(
        'Updated all three icon assets. Deployed in v1.3.0.',
        'هر سه دارایی آیکون به‌روز شدند. در v1.3.0 مستقر شد.',
      );
  static String get msg0704 =>
      _t('Looks perfect now. Resolved.', 'الان عالی به نظر می‌رسد. حل شد.');
  // Ticket 8
  static String get msg0801 => _t(
        'The Apex client tried to upload a 14 MB PDF proposal. Flow got stuck — no error, no progress.',
        'مشتری Apex سعی کرد یک پروپوزال PDF 14 مگابایتی آپلود کند. گردش‌کار گیر کرد — بدون خطا، بدون پیشرفت.',
      );
  static String get msg0802 => _t(
        'This affects our active onboarding flow. Needs fixing before the next client intake.',
        'این گردش‌کار فعال پذیرش ما را تحت تأثیر قرار می‌دهد. قبل از پذیرش مشتری بعدی باید رفع شود.',
      );

  // ── Flow instance metadata ────────────────────────────────────────────────
  static String get instanceMetaClientApex =>
      _t('Apex Dynamics Ltd', 'شرکت آپکس داینامیکس');
  static String get instanceMetaClientBlueSky =>
      _t('BlueSky Ventures', 'سرمایه‌گذاری‌های بلواسکای');
  static String get instanceMetaBugTitle =>
      _t('Memory leak in report generator', 'نشت حافظه در مولد گزارش');
}
