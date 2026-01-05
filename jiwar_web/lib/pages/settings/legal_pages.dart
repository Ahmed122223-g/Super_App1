import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("شروط الاستخدام", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: const Text(
          """
باستخدامك لتطبيق جوار، فإنك توافق على الالتزام بشروط الاستخدام التالية:

1. الاستخدام المقبول:
يجب استخدام التطبيق للأغراض القانونية والمشروعة فقط. يمنع استخدام التطبيق لأي غرض غير قانوني أو ضار بحقوق الآخرين.

2. الحسابات:
أنت مسؤول عن الحفاظ على سرية معلومات حسابك وكلمة المرور الخاصة بك. أنت تتحمل المسؤولية الكاملة عن جميع الأنشطة التي تحدث تحت حسابك.

3. الخدمات:
جوار هو منصة تقنية لربط المستخدمين بمقدمي الخدمات (الأطباء، الصيدليات، المعلمين، الفنيين). نحن لسنا مقدم خدمة مباشر ولا نتحمل مسؤولية جودة الخدمات الطبية أو التعليمية أو الفنية، ولكننا نسعى لضمان أفضل تجربة ممكنة من خلال التحقق من مقدمي الخدمة.

4. المواعيد والحجوزات:
يلتزم المستخدم بالحضور في المواعيد المحجوزة. في حال التكرار في عدم الحضور، قد يتم تعليق الحساب.

5. الملكية الفكرية:
جميع الحقوق محفوظة لتطبيق جوار. يمنع نسخ أو إعادة استخدام أي جزء من التطبيق دون إذن كتابي.

6. التعديلات:
نحتفظ بالحق في تعديل هذه الشروط في أي وقت. استمرارك في استخدام التطبيق يعني موافقتك على الشروط المعدلة.

للتواصل معنا: ahmedmohamed1442006m@gmail.com
          """,
          style: TextStyle(fontSize: 16, height: 1.6),
        ),
      ),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("سياسة الخصوصية", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: const Text(
          """
خصوصيتك مهمة جداً بالنسبة لنا. توضح سياسة الخصوصية هذه كيفية جمع واستخدام وحماية معلوماتك الشخصية.

1. المعلومات التي نجمعها:
نجمع المعلومات التي تقدمها لنا عند التسجيل، مثل الاسم، البريد الإلكتروني، رقم الهاتف، والعنوان. كما قد نجمع معلومات الموقع لتقديم خدمات البحث عن أقرب مقدمي خدمة.

2. كيفية استخدام المعلومات:
نستخدم معلوماتك لتحسين خدماتنا، وتخصيص تجربتك، وتسهيل الحجوزات والطلبات، والتواصل معك بشأن حالة طلبك.

3. مشاركة المعلومات:
لا نبيع معلوماتك الشخصية. قد نشارك المعلومات الضرورية فقط مع مقدمي الخدمات الذين تتفاعل معهم (مثل مشاركة اسمك ورقم هاتفك مع الطبيب أو الصيدلية عند الحجز أو الطلب) لإتمام الخدمة.

4. الأمان:
نستخدم بروتوكولات أمان متقدمة لحماية بياناتك من الوصول غير المصرح به. يتم تشفير كلمات المرور والبيانات الحساسة.

5. حقوقك:
يحق لك الاطلاع على بياناتك، تعديلها، أو طلب حذف حسابك في أي وقت من خلال إعدادات التطبيق.

6. ملفات تعريف الارتباط (Cookies):
قد نستخدم ملفات تعريف الارتباط لتحسين تجربة المستخدم وتحليل الأداء.

لأي استفسارات حول الخصوصية: ahmedmohamed1442006m@gmail.com
          """,
          style: TextStyle(fontSize: 16, height: 1.6),
        ),
      ),
    );
  }
}

class LicensesPage extends StatelessWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("التراخيص", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: const LicensePage(
        applicationName: "جوار",
        applicationVersion: "1.0.0",
        applicationIcon: Icon(Icons.apps),
      ),
    );
  }
}
