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
  String get error       => const {'en':'Error',    'uz':'Xato',        'ru':'Ошибка'}[_k]!;
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

  // ── General UI ────────────────────────────────────────────
  String get close           => const {'en':'Close',  'uz':'Yopish',  'ru':'Закрыть'}[_k]!;
  String get showAll         => const {'en':'All',    'uz':'Hammasi', 'ru':'Все'}[_k]!;
  String get clear           => const {'en':'Clear',  'uz':'Tozalash','ru':'Сбросить'}[_k]!;
  String get cancelShort     => const {'en':'Cancel', 'uz':'Bekor',   'ru':'Отмена'}[_k]!;

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

  // ── Shopping ─────────────────────────────────────────────────────────────────
  String get shopping      => const {'en':'Shopping',       'uz':'Xaridlar',           'ru':'Покупки'}[_k]!;
  String get shoppingLists    => const {'en':'Shopping Lists',    'uz':'Xarid ro\'yxatlari', 'ru':'Списки покупок'}[_k]!;
  String get shoppingList     => const {'en':'Shopping List',     'uz':'Xarid ro\'yxati',    'ru':'Список покупок'}[_k]!;
  String get newList          => const {'en':'New List',          'uz':'Yangi ro\'yxat',     'ru':'Новый список'}[_k]!;
  String get editList         => const {'en':'Edit List',         'uz':'Ro\'yxatni tahrirlash','ru':'Редактировать список'}[_k]!;
  String get deleteList       => const {'en':'Delete List',       'uz':'Ro\'yxatni o\'chirish','ru':'Удалить список'}[_k]!;
  String get deleteListConfirm=> const {'en':'Delete this shopping list and all its items?', 'uz':'Ushbu ro\'yxat va barcha elementlarni o\'chirasizmi?', 'ru':'Удалить этот список и все элементы?'}[_k]!;
  String get listNameHint     => const {'en':'e.g. Weekly Groceries', 'uz':'masalan: Haftalik oziq-ovqat', 'ru':'например: Продукты на неделю'}[_k]!;
  String get noShoppingLists  => const {'en':'No Shopping Lists',  'uz':'Ro\'yxatlar yo\'q',  'ru':'Нет списков покупок'}[_k]!;
  String get createFirstList  => const {'en':'Create your first list\nto plan your shopping', 'uz':'Birinchi ro\'yxatingizni\nyarating', 'ru':'Создайте первый список\nдля планирования покупок'}[_k]!;
  String get noItems          => const {'en':'No items',           'uz':'Elementlar yo\'q',   'ru':'Нет элементов'}[_k]!;
  String get itemsDone        => const {'en':'done',               'uz':'bajarildi',           'ru':'выполнено'}[_k]!;
  String get addItemHint      => const {'en':'Add an item...',     'uz':'Element qo\'shish...','ru':'Добавить элемент...'}[_k]!;
  String get addFirstItem     => const {'en':'Add your first item below', 'uz':'Quyida birinchi elementni qo\'shing', 'ru':'Добавьте первый элемент ниже'}[_k]!;
  String get editItem         => const {'en':'Edit Item',          'uz':'Elementni tahrirlash','ru':'Редактировать элемент'}[_k]!;
  String get itemName         => const {'en':'Item name',          'uz':'Element nomi',        'ru':'Название элемента'}[_k]!;
  String get quantity         => const {'en':'Quantity',           'uz':'Miqdor',              'ru':'Количество'}[_k]!;
  String get quantityHint     => const {'en':'e.g. 2 kg, 3 pcs',  'uz':'masalan: 2 kg, 3 ta', 'ru':'например: 2 кг, 3 шт'}[_k]!;
  String get clearChecked     => const {'en':'Clear done',         'uz':'Bajarilganlarni tozalash', 'ru':'Очистить выполненные'}[_k]!;
  String get done             => const {'en':'Done',               'uz':'Bajarilgan',          'ru':'Выполнено'}[_k]!;
  String get allDone          => const {'en':'All done! 🎉',       'uz':'Hammasi tayyor! 🎉',  'ru':'Всё готово! 🎉'}[_k]!;
  String get shoppingComplete => const {'en':'Shopping complete!', 'uz':'Xarid tugadi!',       'ru':'Покупки завершены!'}[_k]!;

  // ── Search & Filter ─────────────────────────────────────────────────────────
  String get filter          => const {'en':'Filter',           'uz':'Filter',              'ru':'Фильтр'}[_k]!;
  String get clearAll        => const {'en':'Clear All',        'uz':'Hammasini tozalash',  'ru':'Очистить всё'}[_k]!;
  String get applyFilter     => const {'en':'Apply Filter',     'uz':'Filterni qo\'llash', 'ru':'Применить фильтр'}[_k]!;
  String get amountRange     => const {'en':'Amount Range',     'uz':'Miqdor oralig\'i',   'ru':'Диапазон суммы'}[_k]!;
  String get dateRange       => const {'en':'Date Range',       'uz':'Sana oralig\'i',     'ru':'Диапазон дат'}[_k]!;
  String get type            => const {'en':'Type',             'uz':'Tur',                 'ru':'Тип'}[_k]!;
  String get min             => const {'en':'Min',              'uz':'Minimum',             'ru':'Минимум'}[_k]!;
  String get max             => const {'en':'Max',              'uz':'Maksimum',            'ru':'Максимум'}[_k]!;
  String get from            => const {'en':'From',             'uz':'Dan',                 'ru':'С'}[_k]!;
  String get to              => const {'en':'To',               'uz':'Gacha',               'ru':'До'}[_k]!;

  // ── Category Budgets ─────────────────────────────────────────────────────────
  String get categoryBudgets        => const {'en':'Category Budgets',          'uz':'Kategoriya byudjetlari', 'ru':'Бюджеты категорий'}[_k]!;
  String get categoryBudgetsSub     => const {'en':'Set spending limits per category', 'uz':'Kategoriya bo\'yicha limit', 'ru':'Лимиты по категориям'}[_k]!;
  String get categoryBudgetInfo     => const {'en':'Set a monthly spending limit for each category. You will see a warning when you are close to the limit.', 'uz':'Har bir kategoriya uchun oylik xarajat limitini belgilang. Limitga yaqinlashganda ogohlantirish ko\'rasiz.', 'ru':'Установите ежемесячный лимит трат по каждой категории. Вы увидите предупреждение при приближении к лимиту.'}[_k]!;
  String get activeBudgets          => const {'en':'ACTIVE BUDGETS',            'uz':'FAOL BYUDJETLAR',        'ru':'АКТИВНЫЕ БЮДЖЕТЫ'}[_k]!;
  String get addBudgetFor           => const {'en':'ADD BUDGET FOR',            'uz':'BYUDJET QO\'SHISH',     'ru':'ДОБАВИТЬ БЮДЖЕТ ДЛЯ'}[_k]!;
  String get allCategoriesHaveBudget=> const {'en':'All categories have budgets set.', 'uz':'Barcha kategoriyalar byudjetga ega.', 'ru':'У всех категорий установлены бюджеты.'}[_k]!;
  String get used                   => const {'en':'used',   'uz':'ishlatildi', 'ru':'использовано'}[_k]!;

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

  String get savingsRate   => const {'en':'Savings Rate',   'uz':'Jamg\'arma foizi',     'ru':'Норма сбережений'}[_k]!;
  String get monthlyTrend  => const {'en':'6-Month Trend',  'uz':'6 oylik tendensiya',   'ru':'Тенденция 6 месяцев'}[_k]!;
  String get dailySpending => const {'en':'Daily Spending', 'uz':'Kunlik xarajat',       'ru':'Расходы по дням'}[_k]!;

  // ── Export ───────────────────────────────────────────────────────────
  String get exportData       => const {'en':'Export Data',              'uz':'Eksport',                       'ru':'Экспорт данных'}[_k]!;
  String get exportReport     => const {'en':'Export Report',            'uz':'Hisobotni eksport',             'ru':'Экспорт отчёта'}[_k]!;
  String get exportSub        => const {'en':'PDF or Excel export',      'uz':'PDF yoki Excel ga eksport',     'ru':'Экспорт в PDF или Excel'}[_k]!;
  String get exportFormat     => const {'en':'Export Format',            'uz':'Eksport formati',               'ru':'Формат экспорта'}[_k]!;
  String get exportTimePeriod => const {'en':'Time Period',              'uz':'Vaqt oralig\'i',               'ru':'Период времени'}[_k]!;
  String get exportInclude    => const {'en':'Include',                  'uz':'Qo\'shish',                    'ru':'Включить'}[_k]!;
  String get exportPreview    => const {'en':'Preview',                  'uz':'Ko\'rinish',                   'ru':'Предпросмотр'}[_k]!;
  String get exportSuccess    => const {'en':'Export Successful!',       'uz':'Eksport muvaffaqiyatli!',       'ru':'Экспорт успешен!'}[_k]!;
  String get exportPdfReady   => const {'en':'Your PDF report is ready.','uz':'PDF hisobotingiz tayyor.',      'ru':'Ваш PDF отчёт готов.'}[_k]!;
  String get exportXlsReady   => const {'en':'Your Excel file is ready.','uz':'Excel faylingiz tayyor.',       'ru':'Ваш Excel файл готов.'}[_k]!;
  String get exportShare      => const {'en':'Share',                    'uz':'Ulashish',                      'ru':'Поделиться'}[_k]!;
  String get exportOpen       => const {'en':'Open',                     'uz':'Ochish',                        'ru':'Открыть'}[_k]!;
  String get exportNoData     => const {'en':'No data for this period',  'uz':'Bu davr uchun ma\'lumot yo\'q','ru':'Нет данных за этот период'}[_k]!;
  String get exportPDF        => const {'en':'Export PDF',               'uz':'PDF eksport',                   'ru':'Экспорт PDF'}[_k]!;
  String get exportExcel      => const {'en':'Export Excel',             'uz':'Excel eksport',                 'ru':'Экспорт Excel'}[_k]!;
  String get exportPdfLabel   => const {'en':'PDF Report',               'uz':'PDF hisobot',                   'ru':'PDF отчёт'}[_k]!;
  String get exportExcelLabel => const {'en':'Excel Sheet',              'uz':'Excel jadval',                  'ru':'Excel таблица'}[_k]!;
  String get exportPdfSub     => const {'en':'Professional · Charts · Branded','uz':'Professional · Grafiklar','ru':'Профессиональный · Графики'}[_k]!;
  String get exportExcelSub   => const {'en':'3 Sheets · Formulas · Filterable','uz':'3 varaq · Formulalar',  'ru':'3 листа · Формулы · Фильтры'}[_k]!;
  String get exportIncIncome  => const {'en':'Income Transactions',      'uz':'Daromad tranzaksiyalari',       'ru':'Транзакции доходов'}[_k]!;
  String get exportIncExpense => const {'en':'Expense Transactions',     'uz':'Xarajat tranzaksiyalari',       'ru':'Транзакции расходов'}[_k]!;
  String get exportIncCharts  => const {'en':'Category Charts',          'uz':'Kategoriya grafiklari',         'ru':'Диаграммы категорий'}[_k]!;
  String get exportPeriodLabel=> const {'en':'Period',                   'uz':'Davr',                          'ru':'Период'}[_k]!;
  String get periodThisMonth  => const {'en':'This Month',               'uz':'Bu oy',                         'ru':'Этот месяц'}[_k]!;
  String get periodLastMonth  => const {'en':'Last Month',               'uz':'O\'tgan oy',                   'ru':'Прошлый месяц'}[_k]!;
  String get period3Months    => const {'en':'Last 3 Months',            'uz':'So\'nggi 3 oy',                'ru':'3 месяца'}[_k]!;
  String get period6Months    => const {'en':'Last 6 Months',            'uz':'So\'nggi 6 oy',                'ru':'6 месяцев'}[_k]!;
  String get periodThisYear   => const {'en':'This Year',                'uz':'Bu yil',                        'ru':'Этот год'}[_k]!;
  String get periodAllTime    => const {'en':'All Time',                  'uz':'Barcha vaqt',                   'ru':'За всё время'}[_k]!;
  String get exportPdfInfo1   => const {'en':'Cover page with summary cards',       'uz':'Xulosa kartochkali muqova',     'ru':'Обложка со сводными карточками'}[_k]!;
  String get exportPdfInfo2   => const {'en':'Income / Expense / Balance stats',    'uz':'Daromad / Xarajat / Balans',    'ru':'Доходы / Расходы / Баланс'}[_k]!;
  String get exportPdfInfo3   => const {'en':'Spending by category breakdown',      'uz':'Kategoriyalar bo\'yicha xarajat','ru':'Расходы по категориям'}[_k]!;
  String get exportPdfInfo4   => const {'en':'Full transaction table',              'uz':'To\'liq tranzaksiyalar jadvali', 'ru':'Полная таблица транзакций'}[_k]!;
  String get exportPdfInfo5   => const {'en':'Dark branded design',                'uz':'Brendlangan dizayn',             'ru':'Фирменный дизайн'}[_k]!;
  String get exportXlsInfo1   => const {'en':'Sheet 1: Summary & categories',      'uz':'Varaq 1: Xulosa',               'ru':'Лист 1: Сводка и категории'}[_k]!;
  String get exportXlsInfo2   => const {'en':'Sheet 2: Full transaction list',     'uz':'Varaq 2: Tranzaksiyalar',       'ru':'Лист 2: Список транзакций'}[_k]!;
  String get exportXlsInfo3   => const {'en':'Sheet 3: Monthly breakdown',         'uz':'Varaq 3: Oylik tahlil',         'ru':'Лист 3: По месяцам'}[_k]!;
  String get exportXlsInfo4   => const {'en':'Color-coded income / expense rows',  'uz':'Rangli qatorlar',               'ru':'Цветные строки'}[_k]!;
  String get exportXlsInfo5   => const {'en':'Ready for filtering & pivot tables', 'uz':'Filtrlash uchun tayyor',        'ru':'Готов для фильтрации'}[_k]!;

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