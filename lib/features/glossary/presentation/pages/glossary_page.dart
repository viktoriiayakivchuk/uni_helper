import 'package:flutter/material.dart';
import 'dart:ui';
import '../../domain/glossary_item.dart';

class GlossaryPage extends StatefulWidget {
  const GlossaryPage({super.key});

  @override
  State<GlossaryPage> createState() => _GlossaryPageState();
}

class _GlossaryPageState extends State<GlossaryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Всі';

  final List<String> _categories = ['Всі', 'Навчання', 'Адміністрація', 'Фінанси', 'Побут', 'Права', 'Наука'];

  // Значно розширений список термінів (Вимога №3)
  final List<GlossaryItem> _allItems = [
    // --- НАВЧАННЯ ---
    GlossaryItem(
      term: 'ECTS (Кредит)', 
      definition: 'Європейська система перенесення і накопичення кредитів. 1 кредит дорівнює 30 академічним годинам. Для отримання диплома бакалавра необхідно успішно опанувати програму обсягом 240 кредитів. Це "валюта" вашого навчання.',
      category: 'Навчання'
    ),
    GlossaryItem(
      term: 'Модульний контроль', 
      definition: 'Перевірка знань після вивчення частини дисципліни. Зазвичай за семестр проводиться 2 модулі. Оцінки за них сумуються з балами за практичні, що формує ваш підсумковий рейтинг без іспиту (автомат).',
      category: 'Навчання'
    ),
    GlossaryItem(
      term: 'Силабус', 
      definition: 'Ваш головний документ з предмета. Тут прописано: за що ставлять бали, де брати літературу, графік дедлайнів та правила перескладання. Якщо викладач змінює правила "на ходу" — посилайтеся на силабус.',
      category: 'Навчання'
    ),
    GlossaryItem(
      term: 'Перескладання (Комісія)', 
      definition: 'Остання спроба здати предмет. Якщо ви не здали іспит викладачу з двох спроб, призначається комісія (декілька викладачів). Провал на комісії зазвичай веде до відрахування або повторного курсу.',
      category: 'Навчання'
    ),
    GlossaryItem(
      term: 'Академічна різниця', 
      definition: 'Перелік предметів, які студент має доздати при переведенні на іншу спеціальність або в інший університет. Виникає через розбіжності в навчальних планах.',
      category: 'Навчання'
    ),
    GlossaryItem(
      term: 'Вибіркові дисципліни', 
      definition: 'Предмети, які ви обираєте самостійно (зазвичай 25% від усієї програми). Це можливість вивчати те, що вам дійсно цікаво, навіть з інших факультетів.',
      category: 'Навчання'
    ),
    GlossaryItem(
      term: 'Акредитація спеціальності', 
      definition: 'Державна перевірка якості навчання. Якщо спеціальність не акредитована, університет не має права видавати дипломи державного зразка. Завжди перевіряйте статус акредитації!',
      category: 'Навчання'
    ),

    // --- АДМІНІСТРАЦІЯ ---
    GlossaryItem(
      term: 'Деканат', 
      definition: 'Центральний офіс факультету. Очолюється деканом. Тут ви замовляєте студентський, довідки про навчання (для військкомату чи соцзахисту) та погоджуєте індивідуальні графіки.',
      category: 'Адміністрація'
    ),
    GlossaryItem(
      term: 'Вчена рада', 
      definition: 'Колегіальний орган, що приймає ключові рішення: від затвердження тем дисертацій до вибору ректора. Студенти також мають своїх представників у Вченій раді.',
      category: 'Адміністрація'
    ),
    GlossaryItem(
      term: 'Навчальна частина', 
      definition: 'Технічний відділ, що формує розклад пар та іспитів для всього університету. Якщо в розкладі помилка або накладка аудиторій — це питання до них.',
      category: 'Адміністрація'
    ),
    GlossaryItem(
      term: 'Кафедра', 
      definition: 'Базовий підрозділ, де працюють викладачі вашого профілю. Кожен студент "закріплений" за певною кафедрою, де він обирає наукового керівника для курсових робіт.',
      category: 'Адміністрація'
    ),

    // --- ФІНАНСИ ---
    GlossaryItem(
      term: 'Рейтинговий бал', 
      definition: 'Число, що визначає ваше місце у черзі на стипендію. Формула: середній бал сесії (вага 0.9) + додаткові бали за науку/спорт/активізм (вага 0.1).',
      category: 'Фінанси'
    ),
    GlossaryItem(
      term: 'Податкова знижка', 
      definition: 'Повернення державою 18% від вартості контракту. Оформити її можуть батьки, які офіційно працюють, або сам студент, якщо він працевлаштований офіційно.',
      category: 'Фінанси'
    ),
    GlossaryItem(
      term: 'Соціальна стипендія', 
      definition: 'Виплата для пільгових категорій (ВПО, діти учасників БД, сироти). Вона фіксована і не залежить від місця в рейтингу, але потребує вчасного подання документів у соцвідділ.',
      category: 'Фінанси'
    ),

    // --- ПОБУТ ---
    GlossaryItem(
      term: 'Коворкінг', 
      definition: 'Простір для навчання з безкоштовним Wi-Fi та розетками. Часто розташовані в бібліотеках або центральних корпусах. Ідеальне місце для роботи над груповими проєктами.',
      category: 'Побут'
    ),
    GlossaryItem(
      term: 'Студентське містечко', 
      definition: 'Комплекс гуртожитків. Має свою адміністрацію (дирекцію студмістечка), яка відповідає за поселення, перепустки та оплату за проживання.',
      category: 'Побут'
    ),
    GlossaryItem(
      term: 'Старостат', 
      definition: 'Збори всіх старост факультету з деканом. Місце, де оголошують найважливіші новини та вирішують організаційні питання груп.',
      category: 'Побут'
    ),

    // --- ПРАВА ---
    GlossaryItem(
      term: 'Академічна свобода', 
      definition: 'Право студента на власний погляд та критику ідей. Викладач не має права занижувати бал лише через те, що ваша думка не збігається з його власною.',
      category: 'Права'
    ),
    GlossaryItem(
      term: 'Студентський омбудсмен', 
      definition: 'Захисник інтересів студентів. До нього йдуть, якщо ви стали свідком корупції, булінгу з боку викладачів або порушення ваших прав у гуртожитку.',
      category: 'Права'
    ),
    GlossaryItem(
      term: 'Академічна доброчесність', 
      definition: 'Правила чесного навчання: жодного плагіату чи списування. За порушення (наприклад, копіювання чужої курсової) можуть анулювати роботу або відрахувати.',
      category: 'Права'
    ),

    // --- НАУКА ---
    GlossaryItem(
      term: 'Тези доповіді', 
      definition: 'Стислий виклад вашого дослідження (1-2 сторінки). Публікація тез у збірнику конференції дає додаткові бали до рейтингу на стипендію.',
      category: 'Наука'
    ),
    GlossaryItem(
      term: 'Індекс Гірша', 
      definition: 'Показник популярності вченого. Якщо ви бачите високий індекс у свого викладача — це знак того, що він реальний фахівець, якого цитують колеги.',
      category: 'Наука'
    ),
    GlossaryItem(
      term: 'Плагіат (Unicheck)', 
      definition: 'Використання чужих текстів без посилань. Більшість університетів перевіряють роботи через систему Unicheck. Допустимий відсоток унікальності зазвичай вище 70-80%.',
      category: 'Наука'
    ),
  ];



  List<GlossaryItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems;
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchesSearch = item.term.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesCategory = _selectedCategory == 'Всі' || item.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F1),
      appBar: AppBar(
        title: const Text('Енциклопедія Студента', 
          style: TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Блок пошуку (Soft UI)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                decoration: const InputDecoration(
                  hintText: 'Знайти термін...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF2D5A40)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // Горизонтальний вибір категорій
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedCategory = category;
                        _applyFilters();
                      });
                    },
                    selectedColor: const Color(0xFF2D5A40),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF2D5A40),
                      fontWeight: FontWeight.bold
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    side: BorderSide.none,
                    elevation: 2,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Список термінів
          Expanded(
            child: _filteredItems.isEmpty 
              ? const Center(child: Text('Термін не знайдено'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D5A40).withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: ExpansionTile(
                            iconColor: const Color(0xFF2D5A40),
                            collapsedIconColor: const Color(0xFF2D5A40).withOpacity(0.7),
                            title: Text(
                              _filteredItems[index].term,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: Color(0xFF2D5A40),
                                fontSize: 16
                              ),
                            ),
                            subtitle: Text(
                              _filteredItems[index].category,
                              style: TextStyle(color: Colors.grey[600], fontSize: 11),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text(
                                  _filteredItems[index].definition,
                                  style: const TextStyle(
                                    fontSize: 14, 
                                    height: 1.6, 
                                    color: Colors.black87
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}