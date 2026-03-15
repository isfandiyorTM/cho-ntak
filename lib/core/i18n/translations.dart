enum AppLanguage { en, uz, ru }

class Translations {
  final AppLanguage language;
  const Translations(this.language);

  // ── Nav ──────────────────────────────────────────────────
  String get home        => const {'en':'Home',     'uz':"Bosh sahifa", 'ru':'Главная'}[_k]!;
  String get stats       => const {'en':'Stats',    'uz':'Statistika',  'ru':'Статистика'}[_k]!;
  String get settings    => const {'en':'Settings', 'uz':'Sozlamalar',  'ru':'Настройки'}[_k]!;

  // ── Home ─────────────────────────────────────────────────
  String get income      => const {'en':'Income',   'uz':'Daromad',     'ru':'Доходы'}[_k]!;
  String get expense     => const {'en':'Expense',  'uz':'Xarajat',     'ru':'Расходы'}[_k]!;
  String get balance     => const {'en':'Balance',  'uz':'Balans',      'ru':'Баланс'}[_k]!;
  String get transactions=> const {'en':'Transactions','uz':'Tranzaksiyalar','ru':'Транзакции'}[_k]!;
  String get noTransactions => const {'en':'No transactions yet','uz':'Tranzaksiyalar yo\'q','ru':'Нет транзакций'}[_k]!;
  String get addFirst    => const {'en':'Tap + to add your first one','uz':'Birinchisini qo\'shish uchun + ni bosing','ru':'Нажмите + чтобы добавить первую'}[_k]!;
  String get noBudget      => const {'en':'No budget set for this month.','uz':'Bu oy uchun byudjet belgilanmagan.','ru':'Бюджет на этот месяц не задан.'}[_k]!;
  String get noBudgetTitle => const {'en':'No budget','uz':'Byudjet yo\'q','ru':'Бюджет не задан'}[_k]!;
  String get noBudgetBody  => const {'en':'Tap to set a monthly budget','uz':'Oylik byudjet belgilash uchun bosing','ru':'Нажмите, чтобы задать бюджет'}[_k]!;
  String get setBudget   => const {'en':'Set Budget','uz':'Byudjet belgilash','ru':'Задать бюджет'}[_k]!;
  String get add         => const {'en':'Add',      'uz':'Qo\'shish',   'ru':'Добавить'}[_k]!;

  // ── Budget dialog ─────────────────────────────────────────
  String get monthlyBudget   => const {'en':'Set Monthly Budget','uz':'Oylik byudjetni belgilash','ru':'Задать месячный бюджет'}[_k]!;
  String get budgetAmount    => const {'en':'Budget amount','uz':'Byudjet miqdori','ru':'Сумма бюджета'}[_k]!;
  String get cancel          => const {'en':'Cancel','uz':'Bekor qilish','ru':'Отмена'}[_k]!;
  String get set             => const {'en':'Set','uz':'Belgilash','ru':'Задать'}[_k]!;

  // ── Delete dialog ─────────────────────────────────────────
  String get deleteTitle  => const {'en':'Delete transaction?','uz':'Tranzaksiyani o\'chirish?','ru':'Удалить транзакцию?'}[_k]!;
  String get deleteBody   => const {'en':'This action cannot be undone.','uz':'Bu amalni ortga qaytarib bo\'lmaydi.','ru':'Это действие нельзя отменить.'}[_k]!;
  String get delete       => const {'en':'Delete','uz':'O\'chirish','ru':'Удалить'}[_k]!;

  // ── Add transaction ───────────────────────────────────────
  String get addTransaction    => const {'en':'Add Transaction','uz':'Tranzaksiya qo\'shish','ru':'Добавить транзакцию'}[_k]!;
  String get editTransaction   => const {'en':'Edit Transaction','uz':'Tranzaksiyani tahrirlash','ru':'Редактировать транзакцию'}[_k]!;
  String get title             => const {'en':'Title','uz':'Sarlavha','ru':'Название'}[_k]!;
  String get amount            => const {'en':'Amount','uz':'Miqdor','ru':'Сумма'}[_k]!;
  String get category          => const {'en':'Category','uz':'Kategoriya','ru':'Категория'}[_k]!;
  String get date              => const {'en':'Date','uz':'Sana','ru':'Дата'}[_k]!;
  String get note              => const {'en':'Note (optional)','uz':'Izoh (ixtiyoriy)','ru':'Заметка (необязательно)'}[_k]!;
  String get selectCategory    => const {'en':'Please select a category','uz':'Kategoriya tanlang','ru':'Выберите категорию'}[_k]!;
  String get enterTitle        => const {'en':'Please enter a title','uz':'Sarlavha kiriting','ru':'Введите название'}[_k]!;
  String get enterAmount       => const {'en':'Please enter amount','uz':'Miqdor kiriting','ru':'Введите сумму'}[_k]!;
  String get invalidNumber     => const {'en':'Invalid number','uz':'Noto\'g\'ri raqam','ru':'Неверное число'}[_k]!;
  String get greaterThanZero   => const {'en':'Must be greater than 0','uz':'0 dan katta bo\'lishi kerak','ru':'Должно быть больше 0'}[_k]!;

  // ── Stats ─────────────────────────────────────────────────
  String get overview          => const {'en':'Overview','uz':'Umumiy ko\'rinish','ru':'Обзор'}[_k]!;
  String get spendingByCategory=> const {'en':'Spending by Category','uz':'Kategoriyalar bo\'yicha','ru':'По категориям'}[_k]!;
  String get topCategories     => const {'en':'Top Categories','uz':'Asosiy kategoriyalar','ru':'Топ категорий'}[_k]!;
  String get noData            => const {'en':'No data yet','uz':'Ma\'lumot yo\'q','ru':'Нет данных'}[_k]!;
  String get addToSeeStats     => const {'en':'Add transactions to see your stats','uz':'Statistikani ko\'rish uchun tranzaksiya qo\'shing','ru':'Добавьте транзакции для статистики'}[_k]!;

  // ── Categories
  String get categories        => const {'en':'Categories',         'uz':'Kategoriyalar',       'ru':'Категории'}[_k]!;
  String get defaultCategories => const {'en':'Default',            'uz':'Standart',            'ru':'Стандартные'}[_k]!;
  String get customCategories  => const {'en':'My Categories',      'uz':'Mening kategoriyalarim','ru':'Мои категории'}[_k]!;
  String get addCategory       => const {'en':'Add Category',       'uz':'Kategoriya qo\'shish', 'ru':'Добавить'}[_k]!;
  String get editCategory      => const {'en':'Edit Category',      'uz':'Tahrirlash',          'ru':'Изменить'}[_k]!;
  String get categoryName      => const {'en':'Category name',      'uz':'Kategoriya nomi',     'ru':'Название'}[_k]!;
  String get chooseEmoji       => const {'en':'Choose icon',        'uz':'Belgi tanlang',       'ru':'Выберите иконку'}[_k]!;
  String get chooseColor       => const {'en':'Choose color',       'uz':'Rang tanlang',        'ru':'Выберите цвет'}[_k]!;
  String get noCustomCategories=> const {'en':'No custom categories yet','uz':'Hali kategoriya yo\'q','ru':'Нет категорий'}[_k]!;

  // ── Widget
  String get widgetSettings => const {'en':'Home Widget',      'uz':'Uy ekrani vidjet',     'ru':'Виджет'}[_k]!;
  String get widgetOpacity  => const {'en':'Background opacity','uz':'Fon shaffofligi',      'ru':'Прозрачность фона'}[_k]!;

  // ── Savings
  String get savingsGoals => const {'en':"Savings", 'uz':"Jamg'arma", 'ru':'Копилка'}[_k]!;
  String get noSavings    => const {'en':'No goals yet',  'uz':'Hali maqsad yo\'q',     'ru':'Целей пока нет'}[_k]!;
  String get noSavingsSub => const {'en':'Set a savings goal and track your progress', 'uz':"Maqsad qo'ying va rivojlanishni kuzating", 'ru':'Поставьте цель накопления'}[_k]!;
  String get addGoal      => const {'en':'Add Goal',      'uz':'Maqsad qo\'shish',      'ru':'Добавить цель'}[_k]!;

  // ── Lock settings ─────────────────────────────────────
  String get appLock     => const {'en':'App Lock',        'uz':'Ilova qulfi',           'ru':'Блокировка'}[_k]!;
  String get appLockTitle=> const {'en':'PIN Lock',        'uz':'PIN qulf',              'ru':'PIN-блокировка'}[_k]!;
  String get lockOn      => const {'en':'Enabled',         'uz':'Yoqilgan',              'ru':'Включено'}[_k]!;
  String get lockOff     => const {'en':'Disabled',        'uz':"O'chirilgan",           'ru':'Отключено'}[_k]!;
  String get biometric   => const {'en':'Fingerprint',     'uz':'Barmoq izi',            'ru':'Отпечаток пальца'}[_k]!;
  String get biometricSub=> const {'en':'Use fingerprint to unlock','uz':'Qulfni ochish uchun barmoq izidan foydalaning','ru':'Разблокировка отпечатком'}[_k]!;
  String get changePin   => const {'en':'Change PIN',      'uz':'PIN ni o\'zgartirish', 'ru':'Изменить PIN'}[_k]!;

  // ── Notification settings ────────────────────────────────
  String get notifOn      => const {'en':'Enabled',           'uz':'Yoqilgan',                  'ru':'Включено'}[_k]!;
  String get notifOff     => const {'en':'Disabled',          'uz':"O'chirilgan",               'ru':'Отключено'}[_k]!;
  String get morningNotif => const {'en':'Morning reminder',  'uz':'Ertalabki eslatma',         'ru':'Утреннее напоминание'}[_k]!;
  String get testNotif    => const {'en':'Send test',         'uz':'Test yuborish',             'ru':'Отправить тест'}[_k]!;
  String get testNotifSub => const {'en':'Tap to test notifications now','uz':'Hozir sinab ko\'ring','ru':'Нажмите для проверки'}[_k]!;

  // ── Settings ──────────────────────────────────────────────
  String get appearance        => const {'en':'Appearance','uz':"Ko'rinish",'ru':'Внешний вид'}[_k]!;
  String get darkMode          => const {'en':'Dark Mode','uz':"Qorong'u rejim",'ru':'Тёмный режим'}[_k]!;
  String get languages          => const {'en':'Language','uz':'Til','ru':'Язык'}[_k]!;
  String get currency          => const {'en':'Currency','uz':'Valyuta','ru':'Валюта'}[_k]!;
  String get notifications     => const {'en':'Notifications','uz':'Bildirishnomalar','ru':'Уведомления'}[_k]!;
  String get aboutApp          => const {'en':'About App','uz':'Ilova haqida','ru':'О приложении'}[_k]!;
  String get version           => const {'en':'Version 1.0.0','uz':'Versiya 1.0.0','ru':'Версия 1.0.0'}[_k]!;
  String get developer         => const {'en':'Developer','uz':'Dasturchi','ru':'Разработчик'}[_k]!;

  // ── Budget card ───────────────────────────────────────────
  String get editBudget       => const {'en':'Edit Budget',         'uz':'Byudjetni tahrirlash',   'ru':'Изменить бюджет'}[_k]!;
  String get save             => const {'en':'Save',               'uz':'Saqlash',                'ru':'Сохранить'}[_k]!;
  String get deleteBudget     => const {'en':'Delete Budget',      'uz':'Byudjetni o\'chirish',  'ru':'Удалить бюджет'}[_k]!;
  String get deleteBudgetTitle=> const {'en':'Delete budget?',     'uz':'Byudjetni o\'chirasizmi?','ru':'Удалить бюджет?'}[_k]!;
  String get deleteBudgetBody => const {'en':'Budget for this month will be removed.','uz':'Bu oylik byudjet o\'chiriladi.','ru':'Бюджет за этот месяц будет удалён.'}[_k]!;

  String get monthlyBudgetCard => const {'en':'Monthly Budget','uz':'Oylik byudjet','ru':'Месячный бюджет'}[_k]!;
  String get spent             => const {'en':'Spent','uz':'Sarflangan','ru':'Потрачено'}[_k]!;
  String get remaining         => const {'en':'Remaining','uz':'Qoldi','ru':'Осталось'}[_k]!;
  String get limit             => const {'en':'Limit','uz':'Limit','ru':'Лимит'}[_k]!;
  String get overBudget        => const {'en':'Over Budget!','uz':'Byudjet oshdi!','ru':'Бюджет превышен!'}[_k]!;
  String get nearLimit         => const {'en':'Near Limit','uz':'Limtga yaqin','ru':'Близко к лимиту'}[_k]!;

  // ── Categories ────────────────────────────────────────────
  String get catFood       => const {'en':'Food & Dining',  'uz':'Oziq-ovqat',   'ru':'Еда и кафе'}[_k]!;
  String get catTransport  => const {'en':'Transport',      'uz':'Transport',    'ru':'Транспорт'}[_k]!;
  String get catShopping   => const {'en':'Shopping',       'uz':'Xarid',        'ru':'Покупки'}[_k]!;
  String get catHealth     => const {'en':'Health',         'uz':'Salomatlik',   'ru':'Здоровье'}[_k]!;
  String get catSalary     => const {'en':'Salary',         'uz':'Maosh',        'ru':'Зарплата'}[_k]!;
  String get catFreelance  => const {'en':'Freelance',      'uz':'Frilanss',     'ru':'Фриланс'}[_k]!;
  String get catEducation  => const {'en':'Education',      'uz':'Ta\'lim',      'ru':'Образование'}[_k]!;
  String get catBills      => const {'en':'Bills',          'uz':'To\'lovlar',   'ru':'Счета'}[_k]!;
  String get catSports     => const {'en':'Sports',         'uz':'Sport',        'ru':'Спорт'}[_k]!;
  String get catFamily     => const {'en':'Family',         'uz':'Oila',         'ru':'Семья'}[_k]!;
  String get catOther      => const {'en':'Other',          'uz':'Boshqa',       'ru':'Другое'}[_k]!;


  // ── Category delete/reset ────────────────────────────────
  String get deleteCategoryTitle  => const {'en':'Delete category?',      'uz':'Kategoriyani o\'chirish?',    'ru':'Удалить категорию?'}[_k]!;
  String get deleteCategoryBody   => const {'en':'This category will be permanently deleted.', 'uz':'Bu kategoriya butunlay o\'chiriladi.', 'ru':'Категория будет удалена навсегда.'}[_k]!;
  String get deleteDefaultTitle   => const {'en':'Hide category?',        'uz':'Kategoriyani yashirish?',     'ru':'Скрыть категорию?'}[_k]!;
  String get deleteDefaultBody    => const {'en':'This category will be hidden from the list. You can restore it by resetting all categories.', 'uz':'Bu kategoriya ro\'yxatdan yashiriladi.', 'ru':'Категория будет скрыта из списка.'}[_k]!;
  String get resetCategories      => const {'en':'Reset all to default',  'uz':'Hammasini tiklash',           'ru':'Сбросить всё'}[_k]!;
  String get customiseDefault     => const {'en':'Customise default',     'uz':'Standartni sozlash',          'ru':'Настроить стандарт'}[_k]!;
  String _k_getter() {
    switch (language) {
      case AppLanguage.uz: return 'uz';
      case AppLanguage.ru: return 'ru';
      case AppLanguage.en: return 'en';
    }
  }
  String get _k => _k_getter();
}